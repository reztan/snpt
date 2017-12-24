#! ruby
# encoding: Windows-31J
# ���j�b�g�e�X�g����P�̎����d�l���̃x�[�X�𐶐�
# 
# ruby UTSMaker.rb > result.csv
#
# �Ώۂ̃e�X�g��IMPUTLIST�Ŏw�肷��
#
# �e�X�g�̏�����
# {C:�N���X, M:���\�b�h, T: �e�X�g���e, T:�e�X�g�ڍ�, P:�菇, S:�K�i}
# //C <�N���X��>,//T <�R�����g> �`���ŏ���
# C �͐V����C��������܂Ōp���A����������t�@�C�����܂�
# C���ȗ����ꂽ�ꍇ�A�t�B�N�X�`���𗘗p����
# M,T,P,S�̓e�X�g���ɏ���
# M���ȗ����ꂽ�ꍇ�A�e�X�g���𗘗p����
# M�������̓e�X�g�P�[�X���e�����R�����g�̊J�n
# T�͘A�����ĕ���������B���̏ꍇ�A1�s�ڂ��e�X�g���e�A2�s�ڈȍ~���e�X�g�ڍׂɂȂ�
# T��1�s�����Ȃ��ꍇ�A�e�X�g�ڍׂ̓e�X�g���e�Ɠ����ɂȂ�
# P,S�͕���������
#
# �e�X�g�̏������A�ȉ���
=begin
//C �N���X��
TEST(TestCaseName, testName)
{
	//M ���\�b�h��
	//T �e�X�g���e
	//T �e�X�g�ڍ�

	//P �菇
	int arg = 0;
	//P �菇
	bool res = TestTarget(arg, 999, "hoge");
	//S �K�i
	ASSERT_EQ(true, res);
}

=end

# �蓮�Ńt�@�C����
IMPUTLIST =[
"MTcpSockTest.cpp",
"MSelectorTest.cpp",
]

# �����Ńt�@�C����
#IMPUTLIST = Dir["*Test.cpp"]

#####
# ���j�b�g�e�X�g����P�̎����d�l���𐶐����� �N���X
class UTSM
attr_accessor :output # �o�͐�
# ������
def initialize
	@output = STDOUT 
end

# CSV�J���}��؂�e�L�X�g�p�ɗv�f���C��
def tostrings(item)
 rc = false
	if item.include?("\n") or item.include?(",")
		rc = true
	end
	if item.include?('"')
		rc = true
		item = item.gsub(/"/,'""') #"
	end
	return '"' + item + '"' if rc
	return  item
end

# 1�e�X�g�����o��
def prints
	if @teststandard_
			p "Nil classname"		if not @classname_ 
			p "Nil methodname"		if not @methodname_ 
			p "Nil testsubject_"		if not @testsubject_
			p "Nil testditail_"		if not @testditail_ 
			p "Nil testproc_"		if not @testproc_ 
			p "Nil teststandard_"		if not @teststandard_
			p  " #{@classname_} #{@methodname_} #{@testsubject_}  #{@testditail_}"
#		@output << "#{@testcasename_ }::#{@testname_},#{@classname_.inspect},#{@methodname_.inspect},#{@testsubject_.inspect},#{@testditail_.inspect},#{@testproc_.inspect},#{@teststandard_.inspect}\n"

		if @testsubject_ != @testditail_
			taitle = @classname_+"::"+@methodname_+"/"+@testsubject_+"/"+@testditail_
		else
			taitle = @classname_+"::"+@methodname_+"/"+@testsubject_
		end
		#@output << "#{tostrings(taitle)},#{tostrings(@testproc_)},#{tostrings(@teststandard_)}\n"
		#taitle = @classname_+"::"+@methodname_
		@output << "#{tostrings(taitle)},#{tostrings(@testproc_)},#{tostrings(@teststandard_)}\n"
		
            @methodname_ = nil
            @testsubject_ = nil
            @testditail_ = nil
            @testditailflag_ = nil
            @testproc_ = nil
            @testproclinenum_ = 0
            @teststandard_ = nil
            @testproclinenumbind_ = {} # �e�X�g�菇�ԍ��o�C���h
	end
end

# 1�t�@�C��������́��o��
def mmm(filename)
	#@output = File.open(filename+".csv","w")
  File.open(filename) do |inf|
		@classname_ = nil #�N���X��
		@methodname_ = nil # ���\�b�h��
		@testsubject_ = nil # �e�X�g��
		@testditail_ = nil #�e�X�g�ڍ�
		@testditailflag_ = nil #�e�X�g�ڍ�
		@testproc_ = nil # �e�X�g�菇
		@testproclinenum_ = 0 # �e�X�g�菇�ԍ�
		@teststandard_ = nil # �e�X�g�K�i
        @testproclinenumbind_ = {} # �e�X�g�菇�ԍ��o�C���h
		
		inf.each_line do |line| # �s���Ƃɏ���
			#p line
			if /^\s*(?:F_)?TEST(?:_F)?\(\s*(\w+)\s*,\s*(\w+)\s*\)/ =~ line # �e�X�g�̊J�n
                    #	p "#{@classname_} #{@methodname_} #{@testcasename_} #{@testname_} "
					prints()
					@testcasename_ = $1
					@testname_ = $2 
				if not @classname_
					@classname_ = (/(\w+?)Test\w*?$/ =~ @testcasename_) ? $1 : @testcasename_
				end
				if not @methodname_
					@methodname_ = (/(\w+?)Test\w*?$/ =~ @testname_) ? $1 : @testname_
				end
			elsif  /^\s*\/\/M\s+(.*)/ =~ line # //M #���\�b�h��
					prints()
					@methodname_ = $1
			elsif /^\s*\/\/C\s+(.*)/ =~ line # //C # �N���X��
				prints()
				@classname_ = $1
			elsif /^\s*\/\/T\s+(.*)/ =~ line # //T # �e�X�g���e, �e�X�g�ڍ�
				
				if not @testsubject_
					@testsubject_ = $1
					@testditail_ = $1
					@testditailflag_ = nil
				else
					if @testditailflag_
						@testditail_ += "\n" if (@testditail_)
					else
						@testditailflag_ = true
						@testditail_ = ""
					end
				@testditail_ += $1
				end
			elsif /^\s*(?=\/\/).*\/\/P\s+(.*)/ =~ line # //P # �菇,
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
                    @testproc_ += @testproclinenum_.to_s + ". " #�菇�ԍ�
                    testproc = $1
                    if /^\s*@(\d+)\s+/ =~ testproc
                        @testproclinenumbind_[$1.to_i] =  @testproclinenum_
                        testproc = $'
                    end
                    @testproc_ += testproc
			elsif /^\s*(?=\/\/).*\/\/S\s+(.*)/ =~ line # //S  # �K�i
				@teststandard_ += "\n" if (@teststandard_) 
				@teststandard_ = "" if (not @teststandard_)
				test_s = $1
                    if /^\s*@(\d+)\s+/ =~ test_s
                        test_s = @testproclinenumbind_[$1.to_i].to_s+". " + $'
                    end
				test_s.gsub!(/�ڎ��F/, '')
				@teststandard_ += test_s
			elsif /^\s*(?:ASSERT|EXPECT)_(EQ|NE|GE|LE|GT|LT)\(\s*(.+?)\s*,\s*(.+?)\s*\);\s*\/\/S\s+@(\d*)<</ =~ line # //S @<< # �K�i ���ߍ\��
				@teststandard_ += "\n" if (@teststandard_) 
				@teststandard_ = "" if (not @teststandard_)
                if $1 == "EQ"
					test_s = $3 + "=" + $2
				elsif $1 == "NE"
					test_s = $3 + "!=" + $2
				elsif $1 == "GE"
					test_s = $3 + "<=" + $2
				elsif $1 == "GT"
					test_s = $3 + "<" + $2
				elsif $1 == "LE"
					test_s = $3 + ">=" + $2
				elsif $1 == "LT"
					test_s = $3 + ">" + $2
				else
					STDERR << "#{@testcasename_ }::#{@testname_}"
				end
                    if $4
                        test_s = @testproclinenumbind_[$4.to_i].to_s + ". " + test_s
                    end
				@teststandard_ += test_s
				
			elsif /^\s*(?:target(?:\.|->))?(.+?);\s*\/\/P\s+@(\d*)<</ =~ line # //P  @<< # �K�i ���ߍ\��
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
                    if $2
                        @testproclinenumbind_[$2.to_i] =  @testproclinenum_
                    end
				@testproc_ += @testproclinenum_.to_s + ". " #�菇�ԍ�
				@testproc_ += $1 + "���Ă�"
			elsif /^\s*(?:ASSERT|EXPECT)_(EQ|NE|GE|GT|LE|LT)\(\s*(.+?)\s*,\s*(?:target(?:\.|->))?(.+?)\s*\);\s*\/\/PS\s+@(\d*|_)<</ =~ line # //PS  @<< # �K�i ���ߍ\��
			
			
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
				@testproc_ += @testproclinenum_.to_s + ". " #�菇�ԍ�
				@testproc_ += $3 + "���Ă�"
			
				@teststandard_ += "\n" if (@teststandard_) 
				@teststandard_ = "" if (not @teststandard_)
				if $1 == "EQ"
					test_s =  $2 + "��Ԃ�����"
				elsif $1 == "NE"
					test_s =  $2 + "��Ԃ��Ȃ�����"
				elsif $1 == "GE"
					test_s =  $2 + "�ȏ��Ԃ�����"
				elsif $1 == "GT"
					test_s =  $2 + "����Ԃ�����"
				elsif $1 == "LE"
					test_s =  $2 + "�ȉ���Ԃ�����"
				elsif $1 == "LT"
					test_s =  $2 + "������Ԃ�����"
				else
					STDERR << "#{@testcasename_ }::#{@testname_}"
                    end
                    
                    if $4
                        test_s = @testproclinenum_.to_s + ". " + test_s
                        @testproclinenumbind_[$4.to_i] =  @testproclinenum_
                    end
				@teststandard_ += test_s
			end
			#--
		end

  end
					prints()
end
end

##########
## Main
File.open("out.csv", "w"){|f|
IMPUTLIST.each {|e| 
utsm = UTSM.new
utsm.output = f
utsm.mmm e

}
}


