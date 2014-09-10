Puppet::Type.newtype(:mikrotik_interface_6to4) do
  @doc = "Manage Mikrotik 6to4 interface creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The the name of the 6to4 interface."
    isnamevar
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

  newproperty(:localaddress) do
    desc "Local address"
    validate do |value|
      unless value =~ /^(\d+\.){3}\d+$/
        raise ArgumentError, "'%s' is not a valid local address." % value
      end
    end
  end

  newproperty(:mtu) do
    desc "MTU"
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid MTU." % value
      end
      unless value.to_i < 65537
        raise ArgumentError, "'%s' is not a valid MTU (0..65536)." % value
      end
    end
  end

  newproperty(:remoteaddress) do
    desc "Remote address"
    validate do |value|
      unless value =~ /^(\d+\.){3}\d+$/
        raise ArgumentError, "'%s' is not a valid remote address." % value
      end
    end
  end
end
