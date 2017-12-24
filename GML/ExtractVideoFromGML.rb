#! ruby
# encoding: sjis

# GALMonitorのLogからVideoを抽出

# D&D用のカレントディレクトリ修正
Dir.chdir(File.expand_path(File.dirname($0)))
# 入力ファイルチェック
if not ARGV[0]
    puts "err: no input file"
    exit
end

flg = 0
idc = 0
outf = File.open("#{ARGV[0]}.h264","wb")
File.open(ARGV[0]).each_line do |fp|
    if fp =~/\d+:\d+:\d+(?:.\d+)? s fl:\d+ ch:\d+ sz:\d+ Video MEDIA_MESSAGE_CODEC_CONFIG (\h+)/
        stream = $1
        outf.write( [stream].pack("H*"))
    elsif fp =~ /\d+:\d+:\d+(?:.\d+)? s fl:\d+ ch:\d+ sz:\d+ Video MEDIA_MESSAGE_DATA \h+/
        flg = 1
    elsif flg==1 and fp =~ /^(\h+)/
        outf << [$1].pack("H*")
        flg=2
    elsif flg == 2 and fp =~ /idc: (\d)/
        idc = $1.to_i
        flg=3
    elsif flg ==3 and fp =~ /type: (\d+)/
        type = $1.to_i
        outf << [(idc << 5) + type].pack("C")
        flg = 4
    elsif flg==4 and fp =~ /^(\h+)/
        outf << [$1].pack("H*")
        flg = 0
    else
        flg = 0
    end
end


