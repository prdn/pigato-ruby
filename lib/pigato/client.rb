class Pigato::Client

  def initialize broker, conf = {}
    @broker = broker
    @context = ZMQ::Context.new(1)
    @socket = nil

    @conf = {
      :autostart => false,
      :timeout => 2500
    }

    @conf.merge!(conf)

    if @conf[:autostart]
      start
    end
  end

  def request service, request, timeout = @conf[:timeout]
    return nil if @socket == nil;

    request = [Oj.dump(request)]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    msg = ZMQ::Message.new
    request.reverse.each{|p| msg.push(ZMQ::Frame(p))}
    @socket.send_message msg

    res = [] 
    while 1 do
      chunk = _recv(rid, timeout)
      break if chunk == nil
      res << Oj.load(chunk[4])
      break if chunk[0] == Pigato::W_REPLY
    end

    return nil if res.length == 1
    return res[0] if res.length == 0
    res
  end

  def _recv rid, timeout = @timeout
    @socket.rcvtimeo = timeout;
    data = []
    d1 = Time.now
    msg = @socket.recv_message()
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
    $socket.close
  end

  def reconnect_to_broker
    if @socket
      @socket.close
    end

    @socket = @context.socket ZMQ::DEALER
    @context.linger = 0
    @socket.identity = SecureRandom.uuid
    @socket.connect @broker
  end
end
