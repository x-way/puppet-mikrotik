require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ipv6_route).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ipv6_route."

  mk_resource_methods

  def self.lookup(device, route)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ipv6_routes] = dev.parse_routes('ipv6') || {}
    end unless @parse_cache[:ipv6_routes]
    @parse_cache[:ipv6_routes][route]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_route('ipv6', resource[:route], former_properties, properties)
    end
    super
  end
end
