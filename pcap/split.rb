#! ruby
# encoding: utf-8
# 特定ポートのTCP通信のデータを抽出
# 
require "stringio"
require "./BinaryData"
require "./networkstruct"
require "./pcap"
include(BinaryData)



INFILE =  ARGV[0] ? ARGV[0] : "wfd_camera.pcap" 


############
#
$tv_sec = 0
$tv_usec = 0



pcapfile = PCAP.new(INFILE)
File.open("outf.pcap", "wb") do |f|
	PCAPFILEHEADER.write_to_stream(f, pcapfile.fileheader)

	pcapfile.each do |packet, phed|
			sio = StringIO.new(packet)
			eth_header = Ethernet2.read_from_stream(sio)
			next if eth_header.type != 0x800 # IPv4
			ip_header = IPv4Header.read_from_stream(sio)
			next if ip_header.protocol != 0x11 # UDP
			udp_header = UDPHeader.read_from_stream(sio)
			next if udp_header.dstPort != 5004
			
			PCAPPKTHDR.write_to_stream(f, phed)
			f.write(packet)
	end

end
