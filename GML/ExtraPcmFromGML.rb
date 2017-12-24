#! ruby

# GALMonitor�̃��O�t�@�C������I�[�f�B�I�X�g���[���𒊏o
# usage: 
#   ExtraPcmFromGML.rb [-g|-m] [-r[start][-end]] inputfile
# 
# inputfile ���͗pGALMonitor�̃��O�t�@�C��
# Option:
# -g  guidance�X�g���[���݂̂��o��
# -m  Media�X�g���[���݂̂��o��
#     -g-m���� �ȗ��� �����o��
# -r[start][-end] �o�͂����Ԃ��w��
#   start         �o�͊J�n���鎞��
#   end           �o�͒�~���鎞��
# Example:
#  ExtraPcmFromGML.rb GALMonitor�̃��O�t�@�C��   # ���ׂẴX�g���[�����o��
#  ExtraPcmFromGML.rb -g -r16:12:47.740-16:12:49.149  GALMonitor�̃��O�t�@�C��  # 16:12:47.740����16:12:49.149�܂ł�Guidance�X�g���[�����o��
#
# note:
# - GML2CSV.rb�̌��ʂł�OK�B���������Ԏw���@��p�C��
# - �X�g���[����Open�EClose���l�����ɑS�`�����l����1�̃t�@�C���ɂ��Ă��܂��Ă���̂ŕ�������
# - �`�����l���Ƃ������ӂ₷?
# - �ׂ��ȏ����̓��O��؂�\�肵�ē��͂���

require 'optparse'
opt = OptionParser.new
# D&D�p�̃J�����g�f�B���N�g���C��
Dir.chdir(File.expand_path(File.dirname($0)))

#�o�̓t�@�C����
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

# ���̓t�@�C���`�F�b�N
if not ARGV[0]
    puts "err: no input file"
    exit
end

# �o�̓t�@�C��
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
