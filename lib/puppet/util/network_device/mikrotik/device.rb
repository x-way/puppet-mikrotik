require 'puppet/util/network_device/base'
require 'puppet/util/network_device/mikrotik/facts'

class Puppet::Util::NetworkDevice::Mikrotik::Device < Puppet::Util::NetworkDevice::Base

  def initialize(url)
    Puppet.debug("Puppet::Util::NetDevice::Mikrotik::Device:initialize: #{url}")
    super(url)
    transport.default_prompt = /\[[^@\[\]]+@[^@\[\]]+\]\s>\s\z/n
    ObjectSpace.define_finalizer(self, self.class.method(:disconnect).to_proc)
  end

  def connect
    transport.connect unless @transport_connected
    @transport_connected = true
  end

  def self.disconnect
    transport.close
  end

  def command(cmd = nil)
    connect
    out = execute(cmd) if cmd
    yield self if block_given?
    #connect
    out
  end

  def execute(cmd)
        transport.command(cmd)
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Mikrotik::Facts.new(transport)
    facts = {}
    command do |ng|
      facts = @facts.retrieve
    end
    facts
  end

  def parse_firewall_addresslists(family)
    lists = {}
    lines = []
    pos = ''
    flag = ''
    comment = ''
    execute("/#{family} firewall address-list print detail without-paging\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*(\d+)\s([X\s])\s;;;\s(.*)\s*$/
        pos = $1
        flag = $2
        comment = $3
      when /^\s*list=(\S+)\saddress=([^ ]+)\s*$/
        lines << "#{pos} #{flag} comment=#{comment} list=#{$1} address=#{$2}"
      when /.*/
        lines << l
      end
    end
    lines.each do |l|
      case l
      when /^\s*(\d+)\s([X\s])\slist=(\S+)\saddress=([^ ]+)(\/128)?\s*$/
        name = $3
        lists[name] = {:listname => name} unless lists[name]
        lists[name]['pos'] = {} unless lists[name]['pos']
        lists[name]['pos'][$1] = $4
        newdis = ($2 == 'X') ? 'yes' : 'no'
        lists[name][:disabled] = (lists[name][:disabled] and (newdis != lists[name][:disabled])) ? 'maybe' : newdis
        (lists[name][:address] ||= []) << $4
        lists[name][:address].sort!
      when /^\s*(\d+)\s([X\s])\scomment=(.*)\slist=(\S+)\saddress=([^ ]+)(\/128)?\s*$/
        name = $4
        lists[name] = {:listname => name} unless lists[name]
        lists[name]['pos'] = {} unless lists[name]['pos']
        lists[name]['pos'][$1] = $5
        newdis = ($2 == 'X') ? 'yes' : 'no'
        lists[name][:disabled] = (lists[name][:disabled] and (newdis != lists[name][:disabled])) ? 'maybe' : newdis
        lists[name][:comment] = $3
        (lists[name][:address] ||= []) << $5
        lists[name][:address].sort!
      end
    end
    lists
  end

  def update_firewall_addresslist(family, listname, is = {}, should = {})
    lists = parse_firewall_addresslists(family) || {}
    if should[:ensure] == :absent
      Puppet.info "Removing address list #{listname}"
      cmd = "/#{family} firewall address-list remove "
      cmd += lists[listname]['pos'].keys.sort_by(&:to_i).reverse.join(',')
      Puppet.debug("update_#{family}_firewall_addresslist: #{cmd}")
      execute("#{cmd}\r")
      return
    end

    addr_is  = [is[:address]].flatten.sort
    addr_should = [should[:address]].flatten.sort

    if lists[listname]
      Puppet.info "Updating address list #{listname} (#{addr_should.join(',')})"
      if (is[:comment] != should[:comment]) or (is[:disabled] != should[:disabled])
        cmd = "/#{family} firewall address-list set"
        cmd += " comment=\"#{should[:comment]}\"" unless is[:comment] == should[:comment]
        cmd += " disabled=#{should[:disabled]}" unless is[:disabled] == should[:disabled]
        cmd += " numbers=#{lists[listname]['pos'].keys.join(',')}"
        Puppet.debug("update_#{family}_firewall_addresslist: #{cmd}")
        execute("#{cmd}\r")
      end
      if !(addr_is == addr_should)
        (addr_should - addr_is).each do |address|
          cmd = "/#{family} firewall address-list add list=#{listname}"
          cmd += " disabled=#{should[:disabled]}" if should[:disabled]
          cmd += " comment=\"#{should[:comment]}\"" if should[:comment]
          cmd += " address=#{address}"
          Puppet.debug("update_#{family}_firewall_addresslist: #{cmd}")
          execute("#{cmd}\r")
        end

        if (addr_is - addr_should).size > 0
          cmd = "/#{family} firewall address-list remove "
          cmd += lists[listname]['pos'].select{|k,v| (addr_is - addr_should).include? v}.collect{|x| x.first}.sort_by(&:to_i).reverse.join(',')
          Puppet.debug("update_#{family}_firewall_addresslist: #{cmd}")
          execute("#{cmd}\r")
        end
      end
    else
      Puppet.info "Creating address list #{listname} (#{addr_should.join(',')})"
      addr_should.each do |address|
        cmd = "/#{family} firewall address-list add list=#{listname}"
        cmd += " disabled=#{should[:disabled]}" if should[:disabled]
        cmd += " comment=\"#{should[:comment]}\"" if should[:comment]
        cmd += " address=#{address}"
        Puppet.debug("update_#{family}_firewall_addresslist: #{cmd}")
        execute("#{cmd}\r")
      end
    end
  end


  def parse_items(cmd, flags_regex, prop_mapping, name_property=:name, array_properties=[])
    items = {}

    lines = []
    lastline = ''
    execute("#{cmd}\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*(\d+)\s(#{flags_regex})\s;;;\s(.*)\s*$/
        lines << lastline
        lastline = "#{$1} #{$2} comment=\"#{$3}\""
      when /^\s*(\d+)\s(#{flags_regex})\s(.*)\s*$/
        lines << lastline
        lastline = "#{$1} #{$2} #{$3}"
      when /\[[^@\[\]]+@[^@\[\]]+\]\s>\s/
        #transport.default_prompt
        # ignore the prompt
        lines << lastline
        lastline = ''
      when /.*/
        lastline = "#{lastline} #{l}"
      end
    end
    lines << lastline

    lines.each do |l|
      case l
      when /^\s*(\d+)\s(#{flags_regex})\s+(.*?)\s*$/
        item = {'pos' => $1}
        flags = $2
        properties = $3

        # parse_flags with custom code, item is skipped if code does not return anything
        o = yield(flags) if block_given?
        next unless o or !block_given?
        item.merge!(o) if o

        until properties == '' do
          break unless properties
          case properties
          when /^([a-z0-9-]+)="([^"]*)"\s*(.*?)\s*$/
            propkey=$1
            propval=$2
            properties = $3
          when /^([a-z0-9-]+)=([^ ]*)\s*(.*?)\s*$/
            propkey=$1
            propval=$2
            properties = $3
          when /^\s*$/
            properties = ''
          when /^[^=]+?(?:\s+(.*?))?\s*$/
            properties = $1
          end

          next unless prop_mapping[propkey]
          if array_properties.include? propkey
            item[prop_mapping[propkey]] = propval.split(',')
          else
            item[prop_mapping[propkey]] = propval
          end
        end

        next unless item[name_property]
        items[item[name_property]] = item
      end
    end

    items
  end

  def update_item(label, items, cmd_prefix, prop_mapping, name, is={}, should={}, name_property=:name)
    if should[:ensure] == :absent
      Puppet.info "Removing #{label} #{name}"
      cmd = "#{cmd_prefix} remove #{items[name]['pos']}"
      Puppet.debug("update_item(#{label}): #{cmd}")
      execute("#{cmd}\r")
      return
    end

    if items[name]
      Puppet.info "Updating #{label} #{name}"
      cmd = "#{cmd_prefix} set numbers=#{items[name]['pos']}"
    else
      Puppet.info "Creating #{label} #{name}"
      cmd = "#{cmd_prefix} add"
    end
    should[name_property] = name unless should[name_property] # make sure we always have a name (defaults to name)
    prop_mapping.each do |l,k|
      next unless should[k]
      next unless should[k] != is[k]
      val = [should[k]].flatten.join(',')
      val = "\"#{val}\"" if val =~/[\s=]/
      cmd += " #{l}=#{val}"
    end
    Puppet.debug("update_item(#{label}): #{cmd}")
    execute("#{cmd}\r")
  end


  VLAN_PROPERTIES = {
    'name' => :name,
    'arp' => :arp,
    'comment' => :comment,
    'disabled' => :disabled,
    'interface' => :interface,
    'l2mtu' => :l2mtu,
    'mtu' => :mtu,
    'use-service-tag' => :useservicetag,
    'vlan-id' => :vlanid,
  }

  def parse_interface_vlans
    parse_items('/interface vlan print detail without-paging', /[\sXRS]{2}/, VLAN_PROPERTIES) do |flags|
      { :disabled => (flags =~ /X/) ? 'yes' : 'no' }
    end
  end

  def update_interface_vlan(name, is = {}, should = {})
    update_item('VLAN', parse_interface_vlans(), '/interface vlan', VLAN_PROPERTIES, name, is, should)
  end


  ADDRESS_PROPERTIES = {
    'address' => :address,
    'advertise' => :advertise,
    'comment' => :comment,
    'disabled' => :disabled,
    'eui-64' => :eui64,
    'from-pool' => :frompool,
    'interface' => :interface,
    'network' => :network,
    'netmask' => :netmask,
    'broadcast' => :broadcast,
  }

  def parse_addresses(family)
    parse_items("/#{family} address print detail without-paging", /[\sXID][GL]?/, ADDRESS_PROPERTIES, :address) do |flags|
      { :disabled => (flags =~ /X/) ? 'yes' : 'no' } unless flags =~ /D/ # ignore dynamic addresses
    end
  end

  def update_address(family, address, is={}, should={})
    update_item("#{family} address", parse_addresses(family), "/#{family} address", ADDRESS_PROPERTIES, address, is, should, :address)
  end


  ROUTE_PROPERTIES = {
    'bgp-as-path' => :bgpaspath,
    'bgp-atomic-aggregate' => :bgpatomicaggregate,
    'bgp-communities' => :bgpcommunities,
    'bgp-local-pref' => :bgplocalpref,
    'bgp-med' => :bgpmed,
    'bgp-origin' => :bgporigin,
    'bgp-prepend' => :bgpprepend,
    'check-gateway' => :checkgateway,
    'comment' => :comment,
    'disabled' => :disabled,
    'distance' => :distance,
    'dst-address' => :route,
    'gateway' => :gateway,
    'route-tag' => :routetag,
    'scope' => :scope,
    'target-scope' => :targetscope,
    'type' => :type,
    'pref-src' => :prefsrc,
    'routing-mark' => :routingmark,
    'vrf-interface' => :vrfinterface,
  }

  def parse_routes(family)
    parse_items("/#{family} route print detail without-paging", /[\sXADCSrobmPUB]{4}/, ROUTE_PROPERTIES, :route, ['gateway','bgp-communities']) do |flags|
      {
        :disabled => (flags =~ /X/) ? 'yes' : 'no',
        :type => (flags =~ /U/) ? 'unreachable' :
                 ((flags =~ /P/) ? 'prohibit' :
                 ((flags =~ /B/) ? 'blackhole' : 'unicast')),
      } unless flags =~ /[DC]/ # ignore dynamic & connected routes
    end
  end

  def update_route(family, route, is={}, should={})
    update_item("#{family} route", parse_routes(family), "/#{family} route", ROUTE_PROPERTIES, route, is, should, :route)
  end


  TUNNEL_PROPERTIES = {
    'name' => :name,
    'comment' => :comment,
    'disabled' => :disabled,
    'local-address' => :localaddress,
    'mtu' => :mtu,
    'remote-address' => :remoteaddress,
  }

  def parse_interface_6to4s
    parse_items('/interface 6to4 print detail without-paging', /[\sXR]{2}/, TUNNEL_PROPERTIES) do |flags|
      { :disabled => (flags =~ /X/) ? 'yes' : 'no' }
    end
  end

  def update_interface_6to4(name, is = {}, should = {})
    update_item('6to4 tunnel', parse_interface_6to4s(), '/interface 6to4', TUNNEL_PROPERTIES, name, is, should)
  end


  LEASE_PROPERTIES = {
    'address' => :address,
    'comment' => :comment,
    'disabled' => :disabled,
    'address-list' => :addresslist,
    'always-broadcast' => :alwaysbroadcast,
    'block-access' => :blockaccess,
    'client-id' => :clientid,
    'lease-time' => :leasetime,
    'mac-address' => :macaddress,
    'rate-limit' => :ratelimit,
    'server' => :server,
    'use-src-mac' => :usesrcmac,
  }

  def parse_ip_dhcpserver_leases
    parse_items('/ip dhcp-server lease print detail without-paging', /[\sXRDB]/, LEASE_PROPERTIES, :address) do |flags|
      { :disabled => (flags =~ /X/) ? 'yes' : 'no' } unless flags =~ /D/ # ignore dynamic leases
    end
  end

  def update_ip_dhcpserver_lease(address, is = {}, should = {})
    update_item('DHCP lease', parse_ip_dhcpserver_leases(), '/ip dhcp-server lease', LEASE_PROPERTIES, address, is, should, :address)
  end

  OVPNCLIENT_PROPERTIES = {
    'name' => :name,
    'comment' => :comment,
    'disabled' => :disabled,
    'add-default-route' => :adddefaultroute,
    'auth' => :auth,
    'certificate' => :certificate,
    'cipher' => :cipher,
    'connect-to' => :connectto,
    'mac-address' => :macaddress,
    'max-mtu' => :maxmtu,
    'mode' => :mode,
    'password' => :password,
    'port' => :port,
    'profile' => :profile,
    'user' => :user,
  }

  def parse_interface_ovpnclients
    parse_items('/interface ovpn-client print detail without-paging', /[\sXR]{2}/, OVPNCLIENT_PROPERTIES, :name) do |flags|
      { :disabled => (flags =~ /X/) ? 'yes' : 'no' }
    end
  end

  def update_interface_ovpnclient(name, is = {}, should = {})
    update_item('OVPN client', parse_interface_ovpnclients(), '/interface ovpn-client', OVPNCLIENT_PROPERTIES, name, is, should, :name)
  end

end
