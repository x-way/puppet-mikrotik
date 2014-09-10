require 'puppet/provider/mikrotik'

Puppet::Type.type(:mikrotik_interface_vlan).provide :mikrotik, :parent => Puppet::Provider::Mikrotik do

  desc "Mikrotik provider for mikrotik_interface_vlan."

  mk_resource_methods

  def self.lookup(device, name)
    @parse_cache = {} unless @parse_cache
    device.command do |dev|
      @parse_cache[:interface_vlans] = dev.parse_interface_vlans() || {}
    end unless @parse_cache[:interface_vlans]
    @parse_cache[:interface_vlans][name]
  end

  def initialize(device, *args)
    super
  end

  def flush
    device.command do |dev|
      dev.update_interface_vlan(resource[:name], former_properties, properties)
    end
    super
  end
end
