#! ruby
# encoding: Windows-31J
# ユニットテストから単体試験仕様書のベースを生成
# 
# ruby UTSMaker.rb > result.csv
#
# 対象のテストをIMPUTLISTで指定する
#
# テストの書き方
# {C:クラス, M:メソッド, T: テスト内容, T:テスト詳細, P:手順, S:規格}
# //C <クラス名>,//T <コメント> 形式で書く
# C は新しいCを見つけるまで継続、ただし同一ファイル内まで
# Cが省略された場合、フィクスチャを利用する
# M,T,P,Sはテスト毎に書く
# Mが省略された場合、テスト名を利用する
# Mもしくはテストケースが各試験コメントの開始
# Tは連続して複数かける。その場合、1行目がテスト内容、2行目以降がテスト詳細になる
# Tが1行しかない場合、テスト詳細はテスト内容と同じになる
# P,Sは複数書ける
#
# テストの書き方、以下例
=begin
//C クラス名
TEST(TestCaseName, testName)
{
	//M メソッド名
	//T テスト内容
	//T テスト詳細

	//P 手順
	int arg = 0;
	//P 手順
	bool res = TestTarget(arg, 999, "hoge");
	//S 規格
	ASSERT_EQ(true, res);
}

=end

# 手動でファイル列挙
IMPUTLIST =[
"MTcpSockTest.cpp",
"MSelectorTest.cpp",
]

# 自動でファイル列挙
#IMPUTLIST = Dir["*Test.cpp"]

#####
# ユニットテストから単体試験仕様書を生成する クラス
class UTSM
attr_accessor :output # 出力先
# 初期化
def initialize
	@output = STDOUT 
end

# CSVカンマ区切りテキスト用に要素を修正
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

# 1テスト分を出力
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
            @testproclinenumbind_ = {} # テスト手順番号バインド
	end
end

# 1ファイル分を解析＆出力
def mmm(filename)
	#@output = File.open(filename+".csv","w")
  File.open(filename) do |inf|
		@classname_ = nil #クラス名
		@methodname_ = nil # メソッド名
		@testsubject_ = nil # テスト名
		@testditail_ = nil #テスト詳細
		@testditailflag_ = nil #テスト詳細
		@testproc_ = nil # テスト手順
		@testproclinenum_ = 0 # テスト手順番号
		@teststandard_ = nil # テスト規格
        @testproclinenumbind_ = {} # テスト手順番号バインド
		
		inf.each_line do |line| # 行ごとに処理
			#p line
			if /^\s*(?:F_)?TEST(?:_F)?\(\s*(\w+)\s*,\s*(\w+)\s*\)/ =~ line # テストの開始
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
			elsif  /^\s*\/\/M\s+(.*)/ =~ line # //M #メソッド名
					prints()
					@methodname_ = $1
			elsif /^\s*\/\/C\s+(.*)/ =~ line # //C # クラス名
				prints()
				@classname_ = $1
			elsif /^\s*\/\/T\s+(.*)/ =~ line # //T # テスト内容, テスト詳細
				
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
			elsif /^\s*(?=\/\/).*\/\/P\s+(.*)/ =~ line # //P # 手順,
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
                    @testproc_ += @testproclinenum_.to_s + ". " #手順番号
                    testproc = $1
                    if /^\s*@(\d+)\s+/ =~ testproc
                        @testproclinenumbind_[$1.to_i] =  @testproclinenum_
                        testproc = $'
                    end
                    @testproc_ += testproc
			elsif /^\s*(?=\/\/).*\/\/S\s+(.*)/ =~ line # //S  # 規格
				@teststandard_ += "\n" if (@teststandard_) 
				@teststandard_ = "" if (not @teststandard_)
				test_s = $1
                    if /^\s*@(\d+)\s+/ =~ test_s
                        test_s = @testproclinenumbind_[$1.to_i].to_s+". " + $'
                    end
				test_s.gsub!(/目視：/, '')
				@teststandard_ += test_s
			elsif /^\s*(?:ASSERT|EXPECT)_(EQ|NE|GE|LE|GT|LT)\(\s*(.+?)\s*,\s*(.+?)\s*\);\s*\/\/S\s+@(\d*)<</ =~ line # //S @<< # 規格 糖衣構文
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
				
			elsif /^\s*(?:target(?:\.|->))?(.+?);\s*\/\/P\s+@(\d*)<</ =~ line # //P  @<< # 規格 糖衣構文
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
                    if $2
                        @testproclinenumbind_[$2.to_i] =  @testproclinenum_
                    end
				@testproc_ += @testproclinenum_.to_s + ". " #手順番号
				@testproc_ += $1 + "を呼ぶ"
			elsif /^\s*(?:ASSERT|EXPECT)_(EQ|NE|GE|GT|LE|LT)\(\s*(.+?)\s*,\s*(?:target(?:\.|->))?(.+?)\s*\);\s*\/\/PS\s+@(\d*|_)<</ =~ line # //PS  @<< # 規格 糖衣構文
			
			
				@testproclinenum_ += 1
				if @testproc_
					@testproc_ += "\n"
				else
					@testproc_ = ""
				end
				
				@testproc_ += @testproclinenum_.to_s + ". " #手順番号
				@testproc_ += $3 + "を呼ぶ"
			
				@teststandard_ += "\n" if (@teststandard_) 
				@teststandard_ = "" if (not @teststandard_)
				if $1 == "EQ"
					test_s =  $2 + "を返すこと"
				elsif $1 == "NE"
					test_s =  $2 + "を返さないこと"
				elsif $1 == "GE"
					test_s =  $2 + "以上を返すこと"
				elsif $1 == "GT"
					test_s =  $2 + "超を返すこと"
				elsif $1 == "LE"
					test_s =  $2 + "以下を返すこと"
				elsif $1 == "LT"
					test_s =  $2 + "未満を返すこと"
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


