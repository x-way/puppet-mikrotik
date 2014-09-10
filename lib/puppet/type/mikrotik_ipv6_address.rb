Puppet::Type.newtype(:mikrotik_ipv6_address) do
  @doc = "Manage Mikrotik IPv6 address creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:address) do
    desc "The the address."
    isnamevar
    validate do |value|
      unless value =~ /^[a-f0-9:]+(\/(\d|[1-9]\d|1[01]\d|12[0-8]))?$/
        raise ArgumentError, "'%s' is not a valid address." % value
      end
    end
  end

  newproperty(:advertise) do
    desc "Defines whether prefix is advertised via SLAAC"
    newvalues(:no, :yes)
    defaultto(:no)
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
    desc "Defines whether addresslist is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:eui64) do
    desc "Defines whether to calculate an EUI-64 address"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:frompool) do
    desc "From-Pool"
  end

  newproperty(:interface) do
    desc "Interface"
  end

end
