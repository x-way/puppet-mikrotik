require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ipv6_address).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ipv6_address."

  mk_resource_methods

  def self.lookup(device, address)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ipv6_addresses] = dev.parse_addresses('ipv6') || {}
    end unless @parse_cache[:ipv6_addresses]
    @parse_cache[:ipv6_addresses][address]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_address('ipv6', resource[:address], former_properties, properties)
    end
    super
  end
end
