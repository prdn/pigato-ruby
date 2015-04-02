require 'thread'

class Pigato::Client

  def initialize broker, conf = {}
    @broker = broker
    @ctxs = {}
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

  def get_proc_id
    pid = "#" + Process.pid.to_s
    pid
  end
 
  def get_thread_id
    tid = "#" + get_proc_id() + "#" + Thread.current.object_id.to_s
    tid
  end
 
  def request service, request, opts = {}
    return nil if @sockets[get_thread_id()] == nil 
    
    socket = @sockets[get_thread_id()]
    
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
    socket = @sockets[get_thread_id()]
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
    tid = get_thread_id()
    if @sockets[tid]
      @sockets[tid].close
      @sockets.delete(tid)
    end

    pid = get_proc_id()
    if @ctxs[pid]
      @ctxs[pid].destroy
      @ctxs.delete(pid)
    end
  end

  def reconnect_to_broker
    stop

    ctx = ZMQ::Context.new
    ctx.linger = 0
    @ctxs[get_proc_id()] = ctx

    socket = ctx.socket ZMQ::DEALER
    socket.identity = SecureRandom.uuid
    socket.connect @broker
    @sockets[get_thread_id()] = socket
  rescue ZMQ::Error => e
    puts e
  end
end
