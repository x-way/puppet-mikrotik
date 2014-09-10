require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_ip_address).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_ip_address."

  mk_resource_methods

  def self.lookup(device, address)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:ip_addresses] = dev.parse_addresses('ip') || {}
    end unless @parse_cache[:ip_addresses]
    @parse_cache[:ip_addresses][address]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_address('ip', resource[:address], former_properties, properties)
    end
    super
  end
end
