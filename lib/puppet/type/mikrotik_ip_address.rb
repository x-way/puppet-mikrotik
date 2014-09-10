Puppet::Type.newtype(:mikrotik_ip_address) do
  @doc = "Manage Mikrotik IP address creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:address) do
    desc "The the address."
    isnamevar
    validate do |value|
      unless value =~ /^(\d+\.){3}\d+(\/(\d|[12]\d|3[0-2]|(\d+\.){3}\d+))?$/
        raise ArgumentError, "'%s' is not a valid address." % value
      end
    end
  end

  newproperty(:broadcast) do
    desc "broadcast"
    newvalues(/^(\d+\.){3}\d+$/)
  end

  newproperty(:comment) do
    desc "Address comment"
    validate do |value|
      unless value =~ /^[\w\s\.,()-]+$/
        raise ArgumentError, "'%s' is not a valid comment." % value
      end
    end
  end

  newproperty(:disabled) do
    desc "Defines whether address is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:interface) do
    desc "Interface"
  end

  newproperty(:netmask) do
    desc "netmask"
    newvalues(/^(\d+\.){3}\d+$/)
  end

  newproperty(:network) do
    desc "network"
    newvalues(/^(\d+\.){3}\d+$/)
  end

end
