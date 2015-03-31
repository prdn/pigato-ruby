require 'thread'

class Pigato::Client

  def initialize broker, conf = {}
    @mtx = Mutex.new
    @broker = broker
    @ctx = ZMQ::Context.new
    @ctx.linger = 0

    @sockets = {}

    @conf = {
      :autostart => false,
      :timeout => 2500
    }

    @conf.merge!(conf)

    if @conf[:autostart]
      start
    end
  end

  def getid
    tid = "#" + Process.pid.to_s + "|" + Thread.current.object_id.to_s
    tid
  end
 
  def request service, request, opts = {}
    socket = @sockets[getid()]
    return nil if socket == nil;

    request = [Oj.dump(request), Oj.dump(opts)]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    msg = ZMQ::Message.new
    request.reverse.each{|p| msg.push(ZMQ::Frame(p))}
    socket.send_message msg

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
    socket = @sockets[getid()]
    socket.rcvtimeo = @conf[:timeout]
    data = []
    d1 = Time.now
    msg = socket.recv_message()
    while 1 do
      break if !msg || msg.size == 0
      data << msg.pop.data
    end
    data = [] if data[3] != rid

    return nil if data.length == 0

    data.shift
    return data 
  end
  
  def start
    reconnect_to_broker
  end

  def stop
    tid = getid()
    socket = @sockets[tid]
    if socket
      socket.close
      @sockets.delete(tid)
    end
  end

  def reconnect_to_broker
    stop
    socket = @ctx.socket ZMQ::DEALER
    socket.identity = SecureRandom.uuid
    socket.connect @broker
    @sockets[getid()] = socket
  end
end
