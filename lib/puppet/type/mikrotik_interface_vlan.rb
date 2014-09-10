Puppet::Type.newtype(:mikrotik_interface_vlan) do
  @doc = "Manage Mikrotik VLAN interface creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The the name of the VLAN interface."
    isnamevar
  end

  newproperty(:arp) do
    desc "ARP behaviour"
    newvalues(:enabled, :disabled, 'proxy-arp', 'reply-only')
    defaultto(:enabled)
  end

  newproperty(:comment) do
    desc "Interface comment"
    validate do |value|
      unless value =~ /^[\w\s\.,()-]+$/
        raise ArgumentError, "'%s' is not a valid comment." % value
      end
    end
  end

  newproperty(:disabled) do
    desc "Defines whether interface is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:interface) do
    desc "Physical interface to the network where are VLANs"
  end

  newproperty(:l2mtu) do
    desc "Layer 2 MTU"
    newvalues(/\d+/)
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid Layer 2 MTU." % value
      end
      unless value.to_i < 65537
        raise ArgumentError, "'%s' is not a valid Layer 2 MTU (0..65536)." % value
      end
    end
  end

  newproperty(:mtu) do
    desc "MTU"
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid MTU." % value
      end
      unless (value.to_i > 67) or (value.to_i < 65536)
        raise ArgumentError, "'%s' is not a valid MTU (68..65535)." % value
      end
    end
  end

  newproperty(:useservicetag) do
    desc "use-service-tag"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:vlanid) do
    desc "VLAN ID"
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid VLAN ID." % value
      end
      unless (value.to_i > 0) or (value.to_i < 4096)
        raise ArgumentError, "'%s' is not a valid VLAN ID (1..4095)." % value
      end
    end
  end
end
