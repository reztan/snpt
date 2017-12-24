#! ruby
# encoding: sjis
#
# AAPのpcmファイルをwaveに変換

# D&D用のカレントディレクトリ修正
Dir.chdir(File.expand_path(File.dirname($0)))

require "./BinaryData"
include(BinaryData)
$BITRATE = 16
WaveFileHeader = struct {
    var riffheader:	PrimaryType.new("a4", 4, "RIFF")     # RIFFヘッダ
    var filesize:	 I32v                                # 総ファイルサイズ-8
    var waveheder:	PrimaryType.new("a4", 4, "WAVE")     # WAVEヘッダ
    var formatchunkfmt:	PrimaryType.new("a4", 4, "fmt ") # フォーマットチャンク
    var formatsize: I32v                                 # フォーマットサイズ　デフォルト値16
    var formatcode: I16v                                 # フォーマットコード　非圧縮のＰＣＭフォーマットは1
    var channelnum: I16v                                 # チャンネル数　モノラルは1、ステレオは2
    var samplingrate: I32v                               # サンプリングレート　44.1kHzの場合なら44100
    var byteparsec: I32v                                 # バイト／秒　１秒間の録音に必要なバイト数
    var blockarray: I16v                                 # ブロック境界　ステレオ16bitなら、16bit*2 = 32bit = 4byte
    var bitparsample: I16v                               # ビット／サンプル　１サンプルに必要なビット数
    var formatchunkdata:	PrimaryType.new("a4", 4, "data") # dataチャンク
    var formatsizedata: I32v                             # 総ファイルサイズ-126
}

p ARGV[0]
if ARGV[0] =~ /pcm_(\d+(?:.\d+)?)k_(mono|stereo)\.pcm/
    samplingrate =  $1
    channelnum =  $2
    File.open(ARGV[0],"rb") do |inf|
        size = inf.size
        header = WaveFileHeader.new
        header.filesize = size + 36
        header.formatsize = 16
        header.formatcode = 1
        if channelnum == "mono"
            header.channelnum = 1
        elsif channelnum == "stereo"
            header.channelnum = 2
        else
            p "err:channelnum #{channelnum}"
    sleep(2)
            throw "err:channelnum #{channelnum}"
        end
        header.samplingrate = (samplingrate.to_f * 1000).to_i
        p (samplingrate.to_f * 1000).to_i
        header.byteparsec = header.samplingrate * ($BITRATE/2) * header.channelnum
        header.blockarray =  ($BITRATE/2) * header.channelnum
        header.bitparsample =  ($BITRATE) #* header.channelnum
        header.formatsizedata =  size
        File.open(ARGV[0]+".wav", "wb"){|outf| 
            WaveFileHeader.write_to_stream(outf,header)
            outf << inf.read
        }
    end
else
    p "err: no match"
    sleep(2)
    throw "err: no match"
    
end

sleep(2)