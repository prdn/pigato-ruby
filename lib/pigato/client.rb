require "json"
require "ffi-rzmq"
require "securerandom"

class PigatoClient

  def initialize broker
    @broker = broker
    @context = ZMQ::Context.new(1)
    @client = nil
    @poller = ZMQ::Poller.new

    reconnect_to_broker
  end

  def send service, request, timeout = 2500
    request = [request.to_json]

    rid = SecureRandom.uuid
    request = [Pigato::C_CLIENT, Pigato::W_REQUEST, service, rid].concat(request)
    @client.send_strings request

    res = Array.new
    res << rid

    data = Array.new
    while 1 do
      chunk = _recv timeout
      break if chunk == nil 
      data << chunk[4]
      break if chunk[0] == Pigato::W_REPLY
    end

    res << data
    res
  end

  def _recv timeout
    items = @poller.poll(timeout)
    if items 
      messages = []
      d1 = Time.now
      while 1 do
        @client.recv_strings(messages, ZMQ::DONTWAIT)
        break if messages.length > 0 || ((Time.now - d1) * 1000 > timeout)
      end

      return nil if messages.length == 0

      # header
      if messages.shift != Pigato::C_CLIENT
        raise RuntimeError, "Not a valid Pigato message"
      end

      return messages
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
