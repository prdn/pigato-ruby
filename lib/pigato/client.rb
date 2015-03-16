require "oj"
require "securerandom"

class Pigato::Client

  def initialize broker
    @broker = broker
    @context = ZMQ::Context.new(1)
    @socket = nil
    @poller = ZMQ::Poller.new
    @timeout = 2500

    start
  end

  def send service, request, timeout = @timeout
    request = [Oj.dump(request)]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    @socket.send_strings request

    res = [] 
    while 1 do
      chunk = _recv(rid, timeout)
      break if chunk == nil
      res << Oj.load(chunk[4])
      break if chunk[0] == Pigato::W_REPLY
    end

    return res[0] if res.length === 1
    res
  end

  def _recv rid, timeout = @timeout
    items = @poller.poll(timeout)
    if items 
      msg = []
      d1 = Time.now
      while 1 do
        @socket.recv_strings(msg, ZMQ::DONTWAIT)
        msg = [] if msg.length < 5 || msg[3] != rid
        break if msg.length > 0 || ((Time.now - d1) * 1000 > timeout)
        sleep(1.0 / 50.0)
      end

      return nil if msg.length == 0

      # header
      if msg.shift != Pigato::C_CLIENT
        raise RuntimeError, "Not a valid Pigato message"
      end

      return msg 
    end
    nil
  end
  
  def start
    reconnect_to_broker
  end

  def stop
    $socket.close
  end

  def reconnect_to_broker
    if @socket
      @poller.deregister @socket, ZMQ::DEALER
    end

    @socket = @context.socket ZMQ::DEALER
    @socket.setsockopt ZMQ::LINGER, 0
    @socket.setsockopt ZMQ::IDENTITY, SecureRandom.uuid
    @socket.connect @broker
    @poller.register @socket, ZMQ::POLLIN
  end
end
