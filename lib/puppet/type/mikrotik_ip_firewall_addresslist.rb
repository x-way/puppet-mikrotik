Puppet::Type.newtype(:mikrotik_ip_firewall_addresslist) do
  @doc = "Manage Mikrotik firewall address-list creation, modification and deletion."

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
    desc "IP address (A.B.C.D[-A.B.C.D |/0..32 |/A.B.C.D ])"

    def insync?(is)
      is.flatten.sort == should.flatten.sort
    end

    validate do |values|
      [values].flatten.each do |value|
        unless value =~ /^(\d+\.){3}\d+(-(\d+\.){3}\d+|\/(\d|[12]\d|3[012]|(\d+\.){3}\d+))?$/
          raise ArgumentError, "#{value} is not a valid address."
        end
      end
    end
  end
end
