require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_interface_6to4).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_interface_6to4."

  mk_resource_methods

  def self.lookup(device, name)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:interface_6to4s] = dev.parse_interface_6to4s() || {}
    end unless @parse_cache[:interface_6to4s]
    @parse_cache[:interface_6to4s][name]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_interface_6to4(resource[:name], former_properties, properties)
    end
    super
  end
end
