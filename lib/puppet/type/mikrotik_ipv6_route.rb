Puppet::Type.newtype(:mikrotik_ipv6_route) do
  @doc = "Manage Mikrotik IPv6 route creation, modification and deletion."

  apply_to_device

  ensurable

  newparam(:route) do
    desc "The the route prefix."
    isnamevar
    validate do |value|
      unless value =~ /^[a-f0-9:]+(\/(\d|[1-9]\d|1[01]\d|12[0-8]))?$/
        raise ArgumentError, "'%s' is not a valid route." % value
      end
    end
  end

  newproperty(:gateway, :array_matching => :all) do
    desc "Nexthop gateway(s)"
    validate do |values|
      [values].flatten.each do |value|
        unless value =~ /^([a-f0-9:]+(%[^ ]+)?|[^ ]+)$/
          raise ArgumentError, "'%s' is not a valid gateway." % value
        end
      end
    end
  end

  newproperty(:comment) do
    desc "Route comment"
    validate do |value|
      unless value =~ /^[\w\s\.,()-]+$/
        raise ArgumentError, "'%s' is not a valid comment." % value
      end
    end
  end

  newproperty(:disabled) do
    desc "Defines whether route is ignored or used"
    newvalues(:no, :yes)
    defaultto(:no)
  end

  newproperty(:type) do
    desc "Route type"
    newvalues(:unicast, :unreachable)
    defaultto(:unicast)
  end

  newproperty(:distance) do
    desc "Route distance"
    newvalues(/(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])/)
  end

  newproperty(:checkgateway) do
    desc "Route check-gateway"
    newvalues(:ping, :arp)
  end

  newproperty(:targetscope) do
    desc "Route target-scope"
    newvalues(/(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])/)
  end

  newproperty(:scope) do
    desc "Route scope"
    newvalues(/(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])/)
  end

  newproperty(:routetag) do
    desc "Route tag"
    newvalues(/\d+/)
  end

  newproperty(:bgpprepend) do
    desc "Route bgp-prepend"
    newvalues(/\d|1[0-6]/)
  end

  newproperty(:bgporigin) do
    desc "Route bgp-origin"
    newvalues(:igp,:egp,:incomplete)
  end

  newproperty(:bgpmed) do
    desc "Route bgp-med"
    newvalues(/\d+/)
  end

  newproperty(:bgplocalpref) do
    desc "Route bgp-local-pref"
    newvalues(/\d+/)
  end

  newproperty(:bgpcommunities, :array_matching => :all) do
    desc "Route bgp-communities"
    validate do |values|
      [values].flatten.each do |value|
        unless value =~ /^(\d+:\d+|internet|no-advertise|no-export|local-as)$/
          raise ArgumentError, "%s is not a valid bgp-community" % value
        end
      end
    end
  end

  newproperty(:bgpatomicaggregate) do
    desc "Route bgp-atomic-aggregate"
    newvalues(:yes, :no)
  end

  newproperty(:bgpaspath) do
    desc "Route bgp-as-path"
  end

end
