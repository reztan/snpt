#! ruby
# encoding: utf-8

require "./BinaryData"
include(BinaryData)

# pcapファイルのヘッダ
PCAPFILEHEADER = struct {
 var magic: I32v   # #define TCPDUMP_MAGIC (0xa1b2c3d4)
 var version_major: I16v # #define TCPDUMP_MAJOR (2)
 var version_minor: I16v # #define TCPDUMP_MINOR (4)
 var thiszone: I32v # GMT to local correction 
 var sigfigs: I32v # accuracy of timestamps 
 var snaplen: I32v # max length saved portion of each packet
 var linktype: I32v # define DATALINKTYPE_10MB (1)
}

# 時間構造体
timeval = struct {
 var tv_sec: I32v
 var tv_usec: I32v
}

# パケットヘッダ
PCAPPKTHDR = struct {
var ts: timeval
var caplen: I32v
var len: I32v
}

# Pcapファイルクラス
class PCAP
	attr_reader :filename

# 初期化
# filename: ファイル名
	def initialize(filename)
		@filename = filename
		@fileheader = nil
	end
	
# ヘッダファイル取得
	def fileheader
		return @fileheader if @fileheader
		File.open(@filename) do |f|
			@fileheader = PCAPFILEHEADER.read_from_stream(f)
		end
		return @fileheader
	end
	
# いてれーた
# パケットごとにブロックが評価される
#    arg1 : パケット本体
#    arg2(pakt): pcapのパケットヘッダ
	def each
		File.open(@filename) do |f|
			@fileheader = PCAPFILEHEADER.read_from_stream(f)
			until f.eof?
				pakt = PCAPPKTHDR.read_from_stream(f)
				yield(f.read(pakt.caplen), pakt)
			end 
		end
	end
end
