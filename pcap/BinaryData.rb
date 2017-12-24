#!/usr/bin/env ruby
# encoding: utf-8
=begin
#
#include(BinaryData)
#
#
## float3要素のベクトル構造体定義
#Vector = struct{
#  var x: F32
#  var y: F32
#  var z: F32
#}
#
## 3x3のマトリックス構造体定義
#Matrix = struct{
#  var rows: Vector[3]
#}
#
##
#Model = struct{
#  var vertex_count: I32
#  var vertices: Vector[:vertex_count]
#  var matrix: Matrix
##  var len: I32
##  # procを渡してもうチョイ複雑な長さ指定をする
##  var dat: I32[Proc.new{|env| (env[:len]/4}]
##  # 値のチェック
##  var test: I32   ,_v: 3
##  # 値のチェック複雑晩
##  var test2: I32   ,_v: lambda{|e| e<3}
#}
#
## モデル構造体のインスタンス生成
#model = Model.new
#
#model.vertex_count = 2;
#model.vertices[0].x = 1
#
#model.matrix.rows[0].x = 10
#
#
#sio = StringIO.new
#
## バイナリとして書き込む
#Model.write_to_stream(sio, model)
#
##これでsioにはC言語で次のような感じで書いて出力したバイナリと同じフォーマットで入ってる
## struct Vector{ float x, y, z; };
## struct Matrix{ Vector rows[3]; };
## struct Model{ int vertex_count; Vector vertices[vertex_count]; Matrix matrix; };
## Model model = {...};
## fwrite(fp, &model, 1, sizeof(model));
#
## ストリームを一番最初に戻す
#sio.pos = 0
#
## バイナリから読み込んで復元する
#model_deserialized = Model.read_from_stream(sio)
#
## 文字列化して出力
#print model_deserialized
#
## 配列の長さ取得
#model.vertices.length()
#
## 構造体のサイズ取得
#model.sizeof()

# color = enum_("c", 1, 0) {# サイズ指定する
#  defe red: nil # nilなら順番に割り当てる
#  defe blue: nil
#  defe green: 99 # 任意の値指定可能
# }
=end
#require "stringio"
#require "pp"

module BinaryData

class StructType
	def [](key)
		return StructArrayType.new(self, key)
	end
end

class StructArrayData
	def initialize(type, data)
		@type = type
		@data = data
	end
        
        def FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF()
            @type
        end
	def data()
		@data
	end
		
	def fillup(i)
		while i>=@data.length
			@data.push(@type.new)
		end
	end
	
	def [](i)
		fillup(i)
		return @data[i]
	end
	
	def []=(i, v)
		fillup(i)
		@data[i] = v
	end
	
	def length
		@data.length
	end
end

class StructArrayType < StructType
	
	def initialize(type, alength)
		@type = type
		@length = alength
	end
	
	def write_to_stream(stream, data, parent = nil)
		length(parent).times{ |i|
			@type.write_to_stream(stream, data[i], parent)
		}
	end
	def pack(data, parent = nil)
		ret = ""
		length(parent).times{ |i|
			ret += @type.pack(data[i], parent)
		}
		return ret
	end
	
	def get_pack_(data, parent = nil)
		ret = ""
		length(parent).times{ |i|
			ret+=@type.get_pack_(data[i], parent)
		}
		ret
	end
	
	def read_from_stream(stream, parent = nil)
		rlength = length(parent)
		data = Array.new(rlength)
		rlength.times{ |i|
			data[i] = @type.read_from_stream(stream, parent)
		}
		return StructArrayData.new(@type, data);
	end
	
	
	def new
		return StructArrayData.new(@type, [])
	end
	def sizeof(parent = nil)
		return @type.sizeof(parent) * length(parent)
	end
	def length(parent = nil)
		rlength = @length
		if(rlength.is_a?(Symbol))
			rlength = parent[rlength];
		elsif(rlength.is_a?(Proc))
			rlength = rlength.call(parent);
		end
		rlength
	end
end

class PrimaryType < StructType
	def initialize(packformat, bytenum, defaultvalue)
		@packformat = packformat
		@bytenum = bytenum
		@defaultvalue = defaultvalue
		@m={}
	end
	
	def write_to_stream(stream, value, parent = nil) 
		stream.write([value].pack(@packformat))
	end
	def pack(value, parent = nil) 
		return [value].pack(@packformat)
	end

	def get_pack_(value, parent = nil)
		return ([value].pack(@packformat))
	end

	def read_from_stream(stream, parent = nil)
		return stream.read(@bytenum).unpack(@packformat)[0]
	end

	def new() 
		return @defaultvalue
	end
	def sizeof(parent = nil)
		return @bytenum
	end
end

class StructMapData
	def initialize(type, data)
		@type = type
		@data = data
	end
	
        def FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF()
            @type
        end
	def data()
		return @data
	end
	
	def [](i)
		return @data[i]
	end
	
	def []=(i, v)
		@data[i] = v
	end
	
	def method_missing(name, *args)
		if name.to_s =~ /(\w+)=/
			@data[$1.to_sym] = args[0]
		else
			return @data[name]
		end
	end
end

class StructMapType < StructType
	
	def initialize()
		@members = {}
		@veryfy = {}
	end
	
	def define(key, val)
		@members[key] = val
	end
	def veryfy(key, val)
		@veryfy[key] = val
	end
	
	def write_to_stream(stream, data, parent = nil)
		@members.each_pair{ |key, type|
			type.write_to_stream(stream, data[key], data)
		}
	end
	def pack(data, parent = nil)
		ret = ""
		@members.each_pair{ |key, type|
			ret += type.pack(data[key], data)
		}
		return ret
	end
	def get_pack_(data, parent = nil)
		ret = ""
		@members.each_pair{ |key, type|
			ret += type.get_pack_(data[key], data)
		}
		ret
	end
	def read_from_stream(stream, parent = nil)
		data = StructMapData.new(self, {})
		@members.each_pair{ |key, type|
			data[key] = type.read_from_stream(stream, data)
			if @veryfy[key]
				if @veryfy[key].is_a?(Proc)
					if ! @veryfy[key].call(data[key])
						throw "--------------"
					end
				elsif @veryfy[key] != data[key]
					throw "-----------"
				end
			end
		}
		return data
	end
			
	def new()
		data = StructMapData.new(self, {})
		@members.each_pair{ |key, type|
			data[key] = type.new
		}
		return data;
	end
	def sizeof(parent = nil)
		data = StructMapData.new(self, {})
		size = 0
		@members.each_pair{ |key, type|
			size += type.sizeof(data)
		}
		return size
	end
end



class EnumMapData

	def initialize(type, data, members)
		@type = type
		@data = data
		@members = members
	end
	
        def FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF()
            @type
        end
	def data()
		return @data
	end
	
	
	def to_s()
		ret = data()
		@members.each_pair {|key, val|
			if (ret == val)
				ret = key
				break
			end
		}
		ret.to_s
	end
	
	def to_i()
		data()
	end
end

class EnumMapType < StructType
	
	
	
	def initialize(packformat, bytenum, defaultvalue)
		@packformat = packformat
		@bytenum = bytenum
		@defaultvalue = defaultvalue
		@members={}
		@num=0
	end
	
	
	def define(key, val)
		@members[key] = val
	end
	
	def write_to_stream(stream, value, parent = nil) 
		stream.write([value].pack(@packformat))
	end
	def pack( value, parent = nil) 
		return([value].pack(@packformat))
	end

	def get_pack_(value, parent = nil) 
		return ([value].pack(@packformat))
	end
	
	def read_from_stream(stream, parent = nil)
		data = EnumMapData.new(self, stream.read(@bytenum).unpack(@packformat)[0], @members)
		return data
	end
			
	def new()
		data = EnumMapData.new(self, @defaultvalue, @members)
		return data;
	end

	def sizeof(parent = nil)
		return @bytenum
	end
	
	def method_missing(name, *args)
		if name.to_s =~ /(\w+)=/
			#@data[$1.to_sym] = args[0]
			trow NoMethodError
		else
			return @members[name.to_sym]
		end
	end
	
end


def extract(value)
	if(value.is_a?(StructMapData))
		ret = {}
		value.data.each_pair{ |key, val|
			ret[key] = extract(val) 
		}
		return ret
	end

	if(value.is_a?(StructArrayData))
		return value.data.map{|val| extract(val) }
	end
	
	if(value.is_a?(EnumMapData))
		return value.to_s
	end

	return value;
end

def struct(&block)
	ret = StructMapType.new();

	def ret.var(arg)
		flg = true
		name  = nil
		arg.each_pair{ |key, type|
			if flg 
				define(key, type)
				name = key
			elsif key == :_v
				veryfy(name, type)
			end
			#break
			flg = false
		}
	end
	
	ret.instance_eval(&block)

	return ret;
end

def enum_(packformat, bytenum, defaultvalue, &block)
	ret = EnumMapType.new(packformat, bytenum, defaultvalue);
	def ret.defe(arg)
		arg.each_pair{ |key, val|
			if val
				@num = val
			else
				@num += 1
			end
			define(key, @num)
			break
		}
	end
	
	ret.instance_eval(&block)

	return ret;
end


#def print(v)
	#pp extract(v)
#end

I32 = PrimaryType.new("N", 4, 0)
I8 = PrimaryType.new("c", 1, 0)
F32 = PrimaryType.new("g", 4, 0.0)


I32v = PrimaryType.new("V", 4, 0)
I16v = PrimaryType.new("v", 2, 0)
I16 = PrimaryType.new("n", 2, 0)

I32n = PrimaryType.new("N", 4, 0)
I16n = PrimaryType.new("n", 2, 0)



end

