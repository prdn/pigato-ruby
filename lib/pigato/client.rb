require "#{File.dirname(__FILE__)}/base.rb"

class Pigato::Client < Pigato::Base
  @@mtx = Mutex.new
  @@ctxs = {}
  @@sockets = {}

  def initialize broker, conf = {}
    @broker = broker

    @conf = {
      :autostart => false,
      :timeout => 2500
    }

    @conf.merge!(conf)

    init
    
    if @conf[:autostart]
      start
    end
  end

  def send msg
    iid = get_iid
    start if @@sockets[iid] == nil && @conf[:autostart]
    socket = get_socket
    return nil if socket.nil?
    socket.send_message msg
    true
  end

  def request service, request, opts = {}
    request = [Oj.dump(request), Oj.dump(opts)]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    msg = ZMQ::Message.new
    request.reverse.each{|p| msg.push(ZMQ::Frame(p))}

    res = send msg
    return nil if res.nil?

    res = [] 
    while 1 do
      chunk = _recv rid
      break if chunk == nil
      res << Oj.load(chunk[4])
      break if chunk[0] == Pigato::W_REPLY
    end

    return nil if res.length == 0
    return res[0] if res.length == 1
    res
  end

  def _recv rid 
    iid = get_iid
    socket = @@sockets[iid]
    socket.rcvtimeo = @conf[:timeout]
    
    data = []
    
    msg = socket.recv_message()
    while 1 do
      break if msg.nil? || msg.size == 0
      data << msg.pop.data
    end

    if data[3] != rid  
      data = []
      if conf[:logger]
        conf[:logger].error("PigatoClient: RID mismatch")
      end
    end

    return nil if data.length == 0

    data.shift
    return data 
  end
  
  def start
    stop
    sock_create
    super 
  rescue ZMQ::Error => e
    puts e
  end

  def stop
    sock_close
    super 
  end
end
