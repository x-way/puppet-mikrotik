Puppet::Type.newtype(:mikrotik_ipv6_firewall_addresslist) do
  @doc = "Manage Mikrotik ipv6 firewall address-list creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:listname) do
    desc "The address-list name."
    isnamevar
    validate do |value|
      unless value =~ /^[\w\.-]+$/
        raise ArgumentError, "%s is not a valid address-list name." % value
      end
    end
  end

  newproperty(:comment) do
    desc "Address-list comment"
    validate do |value|
      unless value =~ /^[\w\s\.,()-]+$/
        raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end

  newproperty(:disabled) do
    desc "Defines whether address-list is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:address, :array_matching => :all) do
    desc "IPv6 prefix"

    def insync?(is)
      is.flatten.sort == should.flatten.sort
    end

    validate do |values|
      [values].flatten.each do |value|
        unless value =~ /^[0-9a-f:]+(\/(\d|\d\d|1[01]\d|12[0-8]))?$/
          raise ArgumentError, "#{value} is not a valid IPv6 prefix."
        end
      end
    end
  end
end
