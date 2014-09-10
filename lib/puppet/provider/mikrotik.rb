require 'puppet/util/network_device/mikrotik/device'
require 'puppet/provider/network_device'

class Puppet::Provider::Mikrotik < Puppet::Provider::NetworkDevice
  def self.device(url)
    Puppet::Util::NetworkDevice::Mikrotik::Device.new(url)
    @parse_cache = {}
  end
end
