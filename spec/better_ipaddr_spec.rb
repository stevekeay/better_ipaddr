require "spec_helper"
require "better_ipaddr"

describe BetterIpaddr do
  it "has a version number" do
    refute_nil ::BetterIpaddr::VERSION
  end

  it "allows instantiation of specialist IPAddr objects" do
    addr = IPAddr.new("1.0.0.1")
    assert_equal IPAddr::V4[addr.to_i], addr
    assert_equal IPAddr::Base.specialize(addr).class, IPAddr::V4
  end

  it "allows instantiation of specialist IPAddr objects from a string" do
    assert_equal IPAddr::V4, IPAddr::Base.parse("1.0.0.1").class
    assert_equal IPAddr::V6, IPAddr::Base.parse("::1").class
  end

  it "allows instantiation of IPAddrs using various formats" do
    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", IPAddr::V4["255.255.255.0"].to_i]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", IPAddr::V4["255.255.255.0"]]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", "255.255.255.0"]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", "24"]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", 24]
  end

  it "round trips ipv4 with strings" do
    addr = "1.0.0.0/24"
    assert_equal addr, IPAddr::V4[addr].cidr
  end

  it "round trips ipv4 prefix lengths with CIDR strings" do
    assert_equal 24, IPAddr::V4["1.0.0.0/24"].prefix_length
  end

  it "reduces ipv4 network addresses" do
    addr = "1.0.0.1/24"
    refute_equal addr, IPAddr::V4[addr].cidr
  end

  it "round trips ipv4 with integers" do
    addr = IPAddr::V4["1.0.0.1"].to_i
    assert_equal addr, IPAddr::V4[addr].to_i
  end

  it "calculates ipv4 offsets" do
    assert_equal IPAddr::V4["1.0.0.1"] + 1, IPAddr::V4["1.0.0.2"]
    assert_equal IPAddr::V4["1.0.0.1"] - 1, IPAddr::V4["1.0.0.0"]
  end

  it "calculates ipv4 network sizes" do
    assert_equal 1, IPAddr::V4["1.0.0.1"].size
    assert_equal 256, IPAddr::V4["1.0.0.0/24"].size
  end

  it "converts ipv4 networks to ranges" do
    assert_equal((0..255), IPAddr::V4["0.0.0.0/24"].to_range(&:to_i))
    assert_equal((IPAddr::V4["0.0.0.0"]..IPAddr::V4["0.0.0.255"]),
                 IPAddr::V4["0.0.0.0/24"].to_range)
  end

  it "enumerates host addresses within an ipv4 range" do
    net = IPAddr::V4["1.0.0.0/30"]
    assert_equal net.to_a, net.each.to_a
    assert_equal [IPAddr::V4["1.0.0.0"],
                  IPAddr::V4["1.0.0.1"],
                  IPAddr::V4["1.0.0.2"],
                  IPAddr::V4["1.0.0.3"]],
                 net.to_a
  end

  it "calculates ipv4 broadcast addresses" do
    assert_equal IPAddr::V4["1.0.0.255"], IPAddr::V4["1.0.0.0/24"].broadcast
  end

  it "provides ipv4 netmasks in integer or string form" do
    net = IPAddr::V4["1.0.0.0/24"]
    assert_equal net.mask_addr, IPAddr::V4["255.255.255.0"].to_i
    assert_equal net.netmask, "255.255.255.0"
  end

  it "calculates ipv4 wildcard mask strings" do
    assert_equal IPAddr::V4["1.0.0.0/24"].wildcard, "0.0.0.255"
  end

  it "calculates whether an ipv4 network covers another" do
    refute IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.1.0/24"])
    refute IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.0/23"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.0/25"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.64/26"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.128/25"])
  end

  it "pre-computes ipv4 netmasks" do
    # all possible ipv4 netmasks spelled out here, then converted to integers
    ipv4_netmasks = ["0.0.0.0", "128.0.0.0", "192.0.0.0", "224.0.0.0",
                     "240.0.0.0", "248.0.0.0", "252.0.0.0", "254.0.0.0",
                     "255.0.0.0", "255.128.0.0", "255.192.0.0", "255.224.0.0",
                     "255.240.0.0", "255.248.0.0", "255.252.0.0",
                     "255.254.0.0", "255.255.0.0", "255.255.128.0",
                     "255.255.192.0", "255.255.224.0", "255.255.240.0",
                     "255.255.248.0", "255.255.252.0", "255.255.254.0",
                     "255.255.255.0", "255.255.255.128", "255.255.255.192",
                     "255.255.255.224", "255.255.255.240", "255.255.255.248",
                     "255.255.255.252", "255.255.255.254", "255.255.255.255"]
                    .map { |a| IPAddr::V4[a].to_i }

    assert_equal ipv4_netmasks, IPAddr::V4::PREFIX_LENGTH_TO_NETMASK
  end

  it "distingushes ipv4 networks from hosts based on prefix length" do
    assert IPAddr::V4["1.0.0.1"].host?
    refute IPAddr::V4["1.0.0.1/31"].host?

    refute IPAddr::V4["1.0.0.1"].network?
    assert IPAddr::V4["1.0.0.1/31"].network?
  end

  it "distinguishes ipv4 addresses based on address and prefix length" do
    assert(IPAddr::V4["1.0.0.1"] == IPAddr::V4["1.0.0.1/32"])
    refute(IPAddr::V4["1.0.0.0/32"] == IPAddr::V4["1.0.0.0/31"])
  end

  it "orders ipv4 networks based on address and prefix length" do
    assert(IPAddr::V4["1.0.0.1"] < IPAddr::V4["1.0.0.2/31"])
    assert(IPAddr::V4["1.0.0.1/31"] < IPAddr::V4["1.0.0.1"])
  end

  it "calculates containing networks" do
    assert_equal(IPAddr::V4["1.0.0.0/25"].grow(1), IPAddr::V4["1.0.0.0/24"])
  end

  it "identifies network pairs which can be summarized" do
    assert_equal IPAddr::V4["1.0.0.0/23"],
                 IPAddr::V4["1.0.0.0/24"]
                   .summarize_with(IPAddr::V4["1.0.1.0/24"])

    assert_nil IPAddr::V4["1.0.2.0/24"]
                .summarize_with(IPAddr::V4["1.0.0.0/24"])

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0/24"]
                   .summarize_with(IPAddr::V4["1.0.0.0/25"])

    assert_nil IPAddr::V4["1.0.1.0/24"]
                .summarize_with(IPAddr::V4["1.0.2.0/24"])
  end
end
