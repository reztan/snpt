#! ruby

# GALMonitorのログファイルからオーディオストリームを抽出
# usage: 
#   ExtraPcmFromGML.rb [-g|-m] [-r[start][-end]] inputfile
# 
# inputfile 入力用GALMonitorのログファイル
# Option:
# -g  guidanceストリームのみを出力
# -m  Mediaストリームのみを出力
#     -g-m両方 省略時 両方出力
# -r[start][-end] 出力する区間を指定
#   start         出力開始する時間
#   end           出力停止する時間
# Example:
#  ExtraPcmFromGML.rb GALMonitorのログファイル   # すべてのストリームを出力
#  ExtraPcmFromGML.rb -g -r16:12:47.740-16:12:49.149  GALMonitorのログファイル  # 16:12:47.740から16:12:49.149までのGuidanceストリームを出力
#
# note:
# - GML2CSV.rbの結果でもOK。ただし時間指定は@を用修正
# - ストリームのOpen・Closeを考えずに全チャンネルを1つのファイルにしてしまっているので分けたい
# - チャンネルとか条件ふやす?
# - 細かな条件はログを切り貼りして入力して

require 'optparse'
opt = OptionParser.new
# D&D用のカレントディレクトリ修正
Dir.chdir(File.expand_path(File.dirname($0)))

#出力ファイル名
FILE_NAME={
"Media"=>"stream-%d-.pcm_48k_stereo.pcm", 
"Guidance"=>"stream-%d-.pcm_16k_mono.pcm",
"Microphone"=>"Microphone_stream-%d-.pcm_16k_mono.pcm"}


$mediatype="Guidance|Media|Microphone"
$current_mediatype=""
$rec_start=nil
$rec_end=nil
opt.on('-r [start][-end]') {|v| 
    if v =~ /^([^-]+)/
        $rec_start=$1
    end
    if v =~ /-(.*)/
        $rec_end=$1 if $1 != ""
        
    end
}
opt.on('-g') {|v| $mediatype="Guidance" }
opt.on('-m') {|v| $mediatype="Media" }
opt.on('-n') {|v| $mediatype="Microphone" }

opt.parse!(ARGV)

# 入力ファイルチェック
if not ARGV[0]
    puts "err: no input file"
    exit
end

# 出力ファイル
outf = {}
if $mediatype=~/Guidance/
    outf["Guidance"] = File.open(FILE_NAME["Guidance"]%0, "wb")
end
if $mediatype=~/Media/
    outf["Media"] = File.open(FILE_NAME["Media"]%0, "wb")
end
if $mediatype=~/Microphone/
    outf["Microphone"] = File.open(FILE_NAME["Microphone"]%0, "wb")
end
outputflg=nil
if $rec_start==nil
    outputflg=true
end

p ARGV
File.open(ARGV[0]) do |inf|
    
    inf.each do |e|
        if $rec_start and e =~ /^#{$rec_start}/
            outputflg = true
        end
        if $rec_end and outputflg and e =~ /^#{$rec_end}/
            outputflg = nil
        end

        next if outputflg==nil
        
        if e =~ /(#{$mediatype})(?:,| )MEDIA_MESSAGE_DATA \h{16,16}(\h+)/
            stream = $2
            $current_mediatype=$1
            outf[$current_mediatype] << [stream].pack("H*")
        end
    end
end
outf.each{|k,v| v.close}
