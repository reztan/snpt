#! ruby
# GalMonitorのLogをcsv形式に変換
# usage:
#   GML2CSV.rb GalMonitorのLog
#
# note:
#   csvをExcelでみると時間がおかしくなるので先頭に@つけて文字列ひょうじしてる

# D&D用のほげ
Dir.chdir(File.expand_path(File.dirname($0)))

if ARGV.length < 1
	puts "err: no arg"
	sleep(4)
	exit
end
flg =nil
rstr = nil
p ARGV[0]

File.open(ARGV[0]+".csv","w") do |fo|
File.open(ARGV[0]).each_line do |e|
    if e =~ /^(\d\d:\d\d:\d+(?:\.\d+)) (.) (fl:\h+) (ch:\d+) (sz:\d+) /
        fo.puts rstr if rstr
        rstr = '"\''+$1+"\","+$2+","+$3+","+$4+","+$5+","
        t = $'.chomp()
        if t =~ /(\w+) /
            rstr += $1+","+$'+","
        else
            rstr += t+","
        end
        flg = true
    elsif  e =~ /^(\d\d:\d\d:\d+(?:\.\d+)) /
        fo.puts rstr if rstr
        rstr = '"'+$1+"\","+$2+","+$3+","+$4+","+$5+","
        t = $'.chomp()
        if t =~ /(\w+) /
            rstr += $1+","+$'+","
        else
            rstr += t+","
        end
        flg = true
    elsif flg
        rstr += e.chomp()+","
    else
        fo.puts rstr if rstr
        fo.puts e.chomp()+","
        rstr = nil
    end
end
end
