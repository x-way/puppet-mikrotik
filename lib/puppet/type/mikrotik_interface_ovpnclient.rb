Puppet::Type.newtype(:mikrotik_interface_ovpnclient) do
  @doc = "Manage Mikrotik OpenVPN Client interface creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "The the name of the OpenVPN Client interface."
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

  newproperty(:adddefaultroute) do
    desc "Whether to add OVPN remote address as a default route"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:auth) do
    desc "Allowed authentication methods"
    newvalues(:md5, :sha1, :none)
    defaultto(:sha1)
  end

  newproperty(:certificate) do
    desc "Name of the client certificate imported into certificate list"
    newvalues(:none, /.+/)
    defaultto(:none)
  end

  newproperty(:cipher) do
    desc "Allowed ciphers"
    newvalues(:aes128, :aes192, :aes256, :blowfish128, :none)
    defaultto(:blowfish128)
  end

  newproperty(:connectto) do
    desc "Remote address of the OVPN server"
    validate do |value|
      unless value =~ /^(\d+\.){3}\d+$/
        raise ArgumentError, "'%s' is not a valid connect-to value" % value
      end
    end
  end

  newproperty(:macaddress) do
    desc "Mac address of OVPN interface."
    validate do |value|
      unless value =~ /^([a-fA-F0-9]{2}[:\.-]){5}[a-fA-F0-9]{2}$/
        raise ArgumentError, "'%s' is not a valid MAC address" % value
      end
    end
  end

  newproperty(:maxmtu) do
    desc "Maximum MTU."
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid MTU." % value
      end
      unless value.to_i < 65537
        raise ArgumentError, "'%s' is not a valid MTU (0..65536)." % value
      end
    end
  end

  newproperty(:mode) do
    desc "Layer3 or layer2 tunnel mode"
    newvalues(:ip, :ethernet)
    defaultto(:ip)
  end

  newproperty(:password) do
    desc "Password used for authentication"
  end

  newproperty(:port) do
    desc "Port to connect to."
    validate do |value|
      unless value =~ /^\d+$/
        raise ArgumentError, "'%s' is not a valid port." % value
      end
      unless value.to_i < 65536
        raise ArgumentError, "'%s' is not a valid port (0..65535)." % value
      end
    end
  end

  newproperty(:profile) do
    desc "Used PPP profile"
  end

  newproperty(:user) do
    desc "User name used for authentication"
  end
end
