#! ruby
require "./BinaryData"
include(BinaryData)

# Ethernet2
#  DestMac 6:c
#  SrcMac  6:c
#  type        2:n
Ethernet2 = struct {
	var dstMac:   PrimaryType.new("c6", 6, "")
	var srcMac:   PrimaryType.new("c6", 6, "")
	var type:   I16n
}


# IPv4
#  DestMac 6:c
#  SrcMac  6:c
#  type        2:n
IPv4Header = struct {
	var hg: I8
	var dif: I8
	var length: I16n
	var id: I16n
	var flg: I16n
	var ttl: I8
	var protocol: I8 #0x06
	var checksum: I16n
	var srcIP: I32
	var dstIP: I32
}

# TCP
#  DestMac 6:c
#  SrcMac  6:c
#  type        2:n
TCPHeader = struct {
	var srcPort: I16n
	var dstPort: I16n
	var seq: I32
	var ack: I32
	var hlf: I16n
	var windowsize: I16n
	var checksum: I16n
	var padding: I16n
}

# UDP
#  DestMac 6:c
#  SrcMac  6:c
#  type        2:n
UDPHeader = struct {
	var srcPort: I16n
	var dstPort: I16n
	var length: I16n
	var checksum: I16n
}