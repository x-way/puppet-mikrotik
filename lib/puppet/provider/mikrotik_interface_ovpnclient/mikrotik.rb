require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_interface_ovpnclient).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_interface_ovpnclient."

  mk_resource_methods

  def self.lookup(device, name)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:interface_ovpnclients] = dev.parse_interface_ovpnclients() || {}
    end unless @parse_cache[:interface_ovpnclients]
    @parse_cache[:interface_ovpnclients][name]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_interface_ovpnclient(resource[:name], former_properties, properties)
    end
    super
  end
end
