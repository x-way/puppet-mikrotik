Puppet::Type.newtype(:mikrotik_ip_dhcpserver_lease) do
  @doc = "Manage Mikrotik DHCP lease creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:address) do
    desc "The the address/prefix/pool of DHCP lease."
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
    desc "Defines whether address is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:addresslist) do
    desc "address-list"
  end

  newproperty(:alwaysbroadcast) do
    desc "Send all replies as broadcast"
    newvalues(:no, :yes)
  end

  newproperty(:blockaccess) do
    desc "Block access for this client"
    newvalues(:no, :yes)
  end

  newproperty(:clientid) do
    desc "Client identifier"
  end

  newproperty(:leasetime) do
    desc "Lease time"
  end

  newproperty(:macaddress) do
    desc "MAC address"
    validate do |value|
      unless value =~ /^([0-9a-fA-F]{2}[:\.-]){5}[0-9a-fA-F]{2}+$/
        raise ArgumentError, "'%s' is not a valid MAC address." % value
      end
    end
  end

  newproperty(:ratelimit) do
    desc "Bit rate limit for the client"
  end

  newproperty(:server) do
    desc "Server name which serves this client"
  end

  newproperty(:usesrcmac) do
    desc "Use source mac address instead"
    newvalues(:no, :yes)
  end
end
