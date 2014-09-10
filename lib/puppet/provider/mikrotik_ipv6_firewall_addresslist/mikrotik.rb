require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ipv6_firewall_addresslist).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ipv6_firewall_addresslist."

  mk_resource_methods

  def self.lookup(device, listname)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ipv6_firewall_addresslists] = dev.parse_firewall_addresslists('ipv6') || {}
    end unless @parse_cache[:ipv6_firewall_addresslists]
    @parse_cache[:ipv6_firewall_addresslists][listname]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_firewall_addresslist('ipv6', resource[:listname], former_properties, properties)
    end
    super
  end
end
