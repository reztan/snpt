#! ruby
# encoding: utf-8
#require "Fiber"
#require "stringio"
require 'socket'
require 'thread'


# RTSPメッセージ
class MsgBase
    attr_accessor :httpv
    attr_accessor :auto_content_length
    attr_accessor :auto_cseq
    attr_accessor :body

    def initialize
        @auto_content_length = true
        @auto_cseq = true
        @header = {}
    end
    def [](header_name)
        if @header
            return nil if not @header[header_name]
            value = @header[header_name]
            value.empty? ? nil : value.join(", ")
        end
    end
    def []=(field, value)
      @header[field] = [value.to_s]
    end
    def read_header(sock)
        raw_header = []
        if sock
            while line = sock.readline
                break if /\A(\r\n|\n)\z/om =~ line
                raw_header << line
            end
        end
        @header = parse_header(raw_header.join)
    end
    
    def read_body(sock)
        @body = nil
        if sock and self['Content-Length']
            @body = sock.read(self['Content-Length'].to_i)
        end
    end
    def parse_header(raw)
      header = Hash.new([].freeze)
      field = nil
      raw.each_line{|line|
        case line
        when /^([A-Za-z0-9!\#$%&'*+\-.^_`|~]+):\s*(.*?)\s*\z/om
          field, value = $1, $2
          #field.downcase!
          header[field] = [] unless header.has_key?(field)
          header[field] << value
        when /^\s+(.*?)\s*\z/om
          value = $1
          unless field
            raise HTTPStatus::BadRequest, "bad header '#{line}'."
          end
          header[field][-1] << " " << value
        else
          raise HTTPStatus::BadRequest, "bad header '#{line}'."
        end
      }
      header.each{|key, values|
        values.each{|value|
          value.strip!
          value.gsub!(/\s+/, " ")
        }
      }
      header
    end
    
    def make_header
        headerstr = ""
        @header.each do |k,v| 
            headerstr += k+": "+self[k]+"\r\n"
        end
        return headerstr
    end
    def to_s
        str = make_status_line
        if @auto_content_length and @body
            if not self['Content-Length'] || self['Content-Length'].to_i < 0
                @header['Content-Length'] = [@body.length.to_s]
            end
        end
        str += make_header
        str += "\r\n"
        if @body
            str += @body
        end
        return str
    end

end


class ResponseMsg < MsgBase
    attr_accessor :code
    attr_accessor :msg
    def initialize(code, msg, httpv)   #:nodoc: internal use only
        super()
        @code = code
        @msg = msg
        @httpv = httpv
    end
    def make_status_line
        "RTSP/#{@httpv} #{"%03d"%@code} #{@msg}\r\n"
    end
end

class RequestMsg < MsgBase
    attr_accessor :method
    attr_accessor :url
    def initialize(method, url, httpv)   #:nodoc: internal use only
        super()
        @method = method
        @url = url
        @httpv = httpv
    end
    def make_status_line
        "#{@method} #{@url} RTSP/#{@httpv}\r\n"
    end
    
    def doAfter(respons_msg)
    end
end
class RequestMsgS < RequestMsg
    
    attr_accessor :callback
    def initialize(method, url, httpv, &block)   #:nodoc: internal use only
        super(method, url, httpv)
        @callback = block
    end
    def doAfter(respons_msg)
        if @callback
            @callback.call respons_msg
        end
    end
end
def read_status_line(sock)
    str = sock.readline
    if /^\s*RTSP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\r?\n/mo =~ str
        return ResponseMsg.new($2, $3, $1 ? $1 : "0.9")
    elsif /^(\S+)\s+(\S++)(?:\s+RTSP\/(\d+\.\d+))?\r?\n/mo =~ str
        return RequestMsg.new($1, $2, $3 ? $3 : "0.9")
    else
        p "EEE"
    end
end
#あ
######################################
# RTSPサーバー
class RTSPServer
    attr_accessor :cseq
    attr_accessor :sessionid
    attr_accessor :rtp_client_port
    attr_accessor :timeout
    attr_accessor :state
    attr_accessor :known_param
    attr_accessor :set_param
    attr_accessor :state
    def initialize
        @cseq = 0
        @timeout = 30
        @sessionid=0x0101
        @known_param = nil
        @set_param = nil
        @state = :INIT
        @waitforresp = {}
        
    end
    def finalize
        @keepAlive.stop if @keepAlive
    end
    def run(sock)
        @sock = sock
        send_M1Reqest
        while not sock.eof
            msg = read_status_line(sock)
            msg.read_header(sock)
            msg.read_body(sock)
            puts "RECV<<"
            puts msg.to_s.gsub(/^/, "<<")
            if msg.kind_of? RequestMsg
                on_RequestMsg(msg)
            else
                on_ResponseMsg(msg)
            end
        end
    end
    
    def sendmsg(msg)
        puts "SEND>>"
        if msg.kind_of? RequestMsg
            if not msg["CSeq"] and msg.auto_cseq
                msg["CSeq"] = @cseq
                @cseq += 1
            end
            @waitforresp[msg["CSeq"]] = msg
        end
        puts msg.to_s.gsub(/^/, ">>")
        @sock.write(msg.to_s)
    end
    
    ####
    def on_OPTIONS(msg)
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        res["Public"]="org.wfa.wfd1.0, SETUP, TEARDOWN, PLAY, PAUSE, GET_PARAMETER, SET_PARAMETER"
        sendmsg(res)
        if not @known_param
            send_M3Reqest
        end
    end
    
    def on_PLAY(msg)
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        sendmsg(res)
        @state = :PLAYING
    end
    def on_PAUSE(msg)
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        sendmsg(res)
        @state = :PAUSE
    end
    def on_SETUP(msg)
        @rtp_client_port = 0
        
        if  msg["Transport"]
            if msg["Transport"] =~ /client_port=(\d+)/
                @rtp_client_port = $1.to_i
            end
        end
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        res["Session"]="#{"%08X"%@sessionid};timeout=#{@timeout}"
        res["Transport"]=msg["Transport"]+";server_port=5000"
        sendmsg(res)
        @state = :PAUSE
        @keepAlive = KeepAlive.new(self, @timeout)
        @keepAlive.start
    end
    def on_TEARDOWN(msg)
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        sendmsg(res)
        @state = :INIT
        @keepAlive.stop
    end
    def on_orgwfawfd10(msg)
        res = ResponseMsg.new(200, "OK", msg.httpv)
        res["CSeq"]=msg["CSeq"]
        sendmsg(res)
    end
    def on_RequestMsg(msg)
        case msg.method
        when "OPTIONS"
            on_OPTIONS(msg)
        when "SET_PARAMETER"
            on_SET_PARAMETER(msg)
        when "GET_PARAMETER"
            on_GET_PARAMETER(msg)
        when "PLAY"
            on_PLAY(msg)
        when "PAUSE"
            on_PAUSE(msg)
        when "SETUP"
            on_SETUP(msg)
        when "TEARDOWN"
            on_TEARDOWN(msg)
        when "org.wfa.wfd1.0"
            on_orgwfawfd10(msg)
        end
    end
    
    def on_ResponseMsg(msg)
        if msg["CSeq"] and @waitforresp[msg["CSeq"]]
            @waitforresp[msg["CSeq"]].doAfter(msg)
            @waitforresp.delete(msg["CSeq"])
        end
    end
    
    ####
    def send_M1Reqest
        req = RequestMsg.new("OPTIONS", "*", "1.0")
        req['Require'] = "org.wfa.wfd1.0"
        sendmsg(req)
    end
    def send_M3Reqest
        req = RequestMsgS.new("GET_PARAMETER", "rtsp://localhost/wfd1.0", "1.0") {|res|
            @known_param = res.body
            if not @set_param
                send_M4Request
            end
        }
        req['Content-Type'] = "text/parameters"
        body =  <<EOS_
wfd_video_formats
wfd_audio_codecs
wfd_3d_video_formats
wfd_content_protection
wfd_display_edid
wfd_coupled_sink
wfd_client_rtp_ports
EOS_
        body.gsub!(/\r?\n/,"\r\n")
        req.body = body
        sendmsg(req)
    end
    def send_M4Request
        req = RequestMsgS.new("SET_PARAMETER", "rtsp://localhost/wfd1.0", "1.0") {|res|
            @set_param = true 
            if @state == :INIT
                send_M5Request
            end
        }
        req['Content-Type'] = "text/parameters"
        req.body =  <<EOS_
wfd_video_formats: 00 00 01 01 00000023 00000000 00000101 00 0000 0000 00 none none
wfd_audio_codecs: LPCM 00000002 00
wfd_presentation_URL: rtsp://127.0.0.1/wfd1.0/streamid=0 none
wfd_client_rtp_ports: RTP/AVP/UDP;unicast 5004 0 mode=play
EOS_
        req.body.gsub!(/\r?\n/,"\r\n")
        sendmsg(req)
    end
    def send_M5Request
        send_wfd_trigger_method("SETUP")
    end
    def sendKeepAlive
        req = RequestMsg.new("GET_PARAMETER", "rtsp://localhost/wfd1.0", "1.0")
        req['Session'] = "#{"%08X"%@sessionid}"
        sendmsg(req)
    end
    #######
    def send_wfd_trigger_method(method)
        req = RequestMsg.new("SET_PARAMETER", "rtsp://localhost/wfd1.0", "1.0")
        req['Content-Type'] = "text/parameters"
        body =  "wfd_trigger_method: #{method}\r\n"
        body.gsub!(/\r?\n/,"\r\n")
        req.body = body
        sendmsg(req)
    end
end
class KeepAlive
    attr_accessor :timeout
    attr_accessor :reqstop
    def initialize(server, timeout)
        @timeout = timeout
        @server = server
        @mutex = Mutex.new
        @timer = ConditionVariable.new
        @reqstop = nil
    end
    def notify
        @mutex.synchronize{
            @timer.signal
        }
    end
    def stop
        @mutex.synchronize{
            @timer.signal
        }
        @reqstop = true
        @thread.join
    end
    def start
        @thread = Thread.new do
            begin
                while not @reqstop 
                    @starttime = Time.now
                    @mutex.synchronize{
                        @timer.wait(@mutex, @timeout-3)
                    }
                    #@timer.wait(@timeout-3)
                    if @timeout-(Time.now - @starttime) < 3
                        @server.sendKeepAlive
                    end
                end
                
            rescue
                p $!
                puts $!.backtrace.join("\n")
            end
        end
    end
end

#########################################
# メイン処理
$sv = nil
def commder(sv)
    Thread.new do
        while cmd = $<.readline
            #p sv
            p cmd
            if cmd =~ /req\s+([A-Za-z0-9_-]+)/
                sv.send_wfd_trigger_method($1)
            elsif cmd =~ /pause/
            end
        end
    end
end
def severst(bindif, port)
    gs = TCPServer.open(bindif, port)
    addr = gs.addr
    addr.shift
    printf("server is on %s\n", addr.join(":"))
    
    while true
        Thread.start(gs.accept) do |s|       # save to dynamic variable
            print(s, " is accepted\n")
            begin
                $sv = RTSPServer.new
                $cmdth = commder($sv)
                $sv.run(s)
                $sv.finalize
                $sv = nil
            rescue
                p $!
                puts $!.backtrace.join("\n")
            end
            print(s, " is gone\n")
            s.close
            $cmdth.terminate
        end
    end
end
######################################

#severst("169.254.123.15",7236)
severst("127.0.0.1",7236)