require "json"
require "ffi-rzmq"
require "securerandom"

class PigatoClient

  def initialize broker
    @broker = broker
    @context = ZMQ::Context.new(1)
    @client = nil
    @poller = ZMQ::Poller.new
    @timeout = 2500

    reconnect_to_broker
  end

  def send service, request, timeout = @timeout
    request = [request.to_json]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    @client.send_strings request

    res = [] 
    while 1 do
      chunk = _recv(rid, timeout)
      break if chunk == nil
      res << chunk[4]
      break if chunk[0] == Pigato::W_REPLY
    end

    res
  end

  def _recv rid, timeout = @timeout
    items = @poller.poll(timeout)
    if items 
      msg = []
      d1 = Time.now
      while 1 do
        @client.recv_strings(msg, ZMQ::DONTWAIT)
        msg = [] if msg.length < 5 || msg[3] != rid
        break if msg.length > 0 || ((Time.now - d1) * 1000 > timeout)
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

  def reconnect_to_broker
    if @client
      @poller.deregister @client, ZMQ::DEALER
    end

    @client = @context.socket ZMQ::DEALER
    @client.setsockopt ZMQ::LINGER, 0
    @client.setsockopt ZMQ::IDENTITY, SecureRandom.uuid
    @client.connect @broker
    @poller.register @client, ZMQ::POLLIN
  end
end
