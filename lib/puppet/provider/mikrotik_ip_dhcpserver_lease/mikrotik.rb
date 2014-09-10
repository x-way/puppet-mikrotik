require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ip_dhcpserver_lease).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ip_dhcpserver_lease."

  mk_resource_methods

  def self.lookup(device, name)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ip_dhcpserver_leases] = dev.parse_ip_dhcpserver_leases() || {}
    end unless @parse_cache[:ip_dhcpserver_leases]
    @parse_cache[:ip_dhcpserver_leases][name]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_ip_dhcpserver_lease(resource[:name], former_properties, properties)
    end
    super
  end
end
