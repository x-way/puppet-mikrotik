require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ip_route).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ip_route."

  mk_resource_methods

  def self.lookup(device, route)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ip_routes] = dev.parse_routes('ip') || {}
    end unless @parse_cache[:ip_routes]
    @parse_cache[:ip_routes][route]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_route('ip', resource[:route], former_properties, properties)
    end
    super
  end
end
