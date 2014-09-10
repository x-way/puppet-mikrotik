require 'puppet/util/network_device/mikrotik'
require 'puppet/util/network_device/ipcalc'

class Puppet::Util::NetworkDevice::Mikrotik::Facts

  include Puppet::Util::NetworkDevice::IPCalc

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    facts = {}
    facts.merge!(parse_resource_print)
    facts.merge!(parse_routerboard_print)
    facts.merge!(parse_identity_print)
    facts.merge!(parse_license_print)
    facts.merge!(parse_addresses)
    facts
  end

  def parse_addresses
    facts = {}
    interfaces = []

    lines = []
    lastline = ''
    [ @transport.command("/ip address print terse\r").split(/[\n\r]+/),
      @transport.command("/ipv6 address print terse\r").split(/[\n\r]+/)
    ].flatten.each do |l|
      case l
        when /^\s*\d+\s.[GL]?\s/
          lines << lastline
          lastline = l
        when /\[[^@\[\]]+@[^@\[\]]+\]\s>\s/
          #transport.default_prompt
          # ignore the prompt
          lines << lastline
          lastline = ''
        when /.*/
          lastline = "#{lastline}#{l}"
      end
    end
    lines << lastline

    lines.each do |l|
      case l
      when /\saddress=(#{IP})\/(\d+).*?\snetwork=(#{IP})\s.*?interface=([^ ]+)/
        facts["ipaddress_#{$4}"] = $1
        facts["netmask_#{$4}"]   = netmask(Socket::AF_INET,$2.to_i).to_s
        facts["network_#{$4}"]   = $3
        interfaces << $4
      when /^\s*\d+\s.G\s.*address=(#{IP})\/\d+.*?\sinterface=([^ ]+)/
        # only consider Global addresses
        facts["ipaddress6_#{$2}"] = $1
        interfaces << $2
      end
    end

    facts ['interfaces'] = interfaces.sort.uniq.join(',')
    facts
  end

  def parse_license_print
    facts = {}
    @transport.command("/system license print\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*software-id:\s(.+)/
        facts['software-id'] = $1
      when /^\s*upgradable-to:\s(.+)/
        facts['upgradable-to'] = $1
      when /^\s*nlevel:\s(.+)/
        facts['nlevel'] = $1
      when /^\s*features:\s(.*)/
        facts['features'] = $1
      end
    end
    facts
  end

  def parse_identity_print
    facts = {}
    @transport.command("/system identity print\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*name:\s(.+)/
        facts['hostname'] = $1
      end
    end
    facts
  end

  def parse_routerboard_print
    facts = {}
    @transport.command("/system routerboard print\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*routerboard:\s(.+)/
        facts['routerboard'] = $1
      when /^\s*model:\s(.+)/
        facts['productname'] = $1
      when /^\s*serial-number:\s(.+)/
        facts['serialnumber'] = $1
      when /^\s*current-firmware:\s(.+)/
        facts['currentfirmware'] = $1
      when /^\s*upgrade-firmware:\s(.+)/
        facts['upgradefirmware'] = $1
      end
    end
    facts
  end

  def parse_resource_print
    facts = {}
    @transport.command("/system resource print\r").split(/[\n\r]+/).each do |l|
      case l
      when /^\s*uptime:\s(\S+)/
        facts['uptime_seconds'] = uptime_to_seconds($1)
        facts['uptime_hours'] = facts['uptime_seconds'].to_i / (60 * 60)
        facts['uptime_days'] = facts['uptime_hours'].to_i / 24
        facts['uptime'] = "#{String(facts['uptime_days'])} days"
      when /^\s*version:\s(.*)/
        facts['operatingsystemrelease'] = $1
      when /^\s*platform:\s(.*)/
        facts['operatingsystem'] = $1
      when /^\s*architecture-name:\s(.*)/
        facts['architecture'] = $1
      when /^\s*cpu-count:\s(.*)/
        facts['processorcount'] = $1.to_i
      when /^\s*cpu:\s(.*)/
        facts['processor0'] = $1
      when /^\s*board-name:\s(.*)/
        facts['boardproductname'] = $1
      when /^\s*free-memory:\s(.*)/
        facts['memoryfree'] = $1
      when /^\s*total-memory:\s(.*)/
        facts['memorytotal'] = $1
        facts['memorysize'] = $1
      end
    end
    facts
  end

  def uptime_to_seconds(uptime)
    captures = (uptime.match /^(?:(\d+)w)?(?:(\d+)d)?(?:(\d+)h)?(?:(\d+)m)?(\d+)s/).captures
    captures.zip([7*24*60*60, 24*60*60, 60*60, 60, 1]).inject(0) do |total, (x,y)|
      total + (x.nil? ? 0 : x.to_i * y)
    end
  end
end
