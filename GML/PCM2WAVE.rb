#! ruby
# encoding: sjis
#
# AAP��pcm�t�@�C����wave�ɕϊ�

# D&D�p�̃J�����g�f�B���N�g���C��
Dir.chdir(File.expand_path(File.dirname($0)))

require "./BinaryData"
include(BinaryData)
$BITRATE = 16
WaveFileHeader = struct {
    var riffheader:	PrimaryType.new("a4", 4, "RIFF")     # RIFF�w�b�_
    var filesize:	 I32v                                # ���t�@�C���T�C�Y-8
    var waveheder:	PrimaryType.new("a4", 4, "WAVE")     # WAVE�w�b�_
    var formatchunkfmt:	PrimaryType.new("a4", 4, "fmt ") # �t�H�[�}�b�g�`�����N
    var formatsize: I32v                                 # �t�H�[�}�b�g�T�C�Y�@�f�t�H���g�l16
    var formatcode: I16v                                 # �t�H�[�}�b�g�R�[�h�@�񈳏k�̂o�b�l�t�H�[�}�b�g��1
    var channelnum: I16v                                 # �`�����l�����@���m������1�A�X�e���I��2
    var samplingrate: I32v                               # �T���v�����O���[�g�@44.1kHz�̏ꍇ�Ȃ�44100
    var byteparsec: I32v                                 # �o�C�g�^�b�@�P�b�Ԃ̘^���ɕK�v�ȃo�C�g��
    var blockarray: I16v                                 # �u���b�N���E�@�X�e���I16bit�Ȃ�A16bit*2 = 32bit = 4byte
    var bitparsample: I16v                               # �r�b�g�^�T���v���@�P�T���v���ɕK�v�ȃr�b�g��
    var formatchunkdata:	PrimaryType.new("a4", 4, "data") # data�`�����N
    var formatsizedata: I32v                             # ���t�@�C���T�C�Y-126
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