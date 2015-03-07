module Pigato
  class Client
    include MDP

    attr_accessor :timeout

    def initialize broker
      @broker = broker
      @context = ZMQ::Context.new(1)
      @client = nil
      @poller = ZMQ::Poller.new
      @timeout = 2500

      reconnect_to_broker
    end

    def send service, request, timeout = 2500
      request = [request.to_json]

      rid = 'RID' + (rand() * 1000000).to_s
      # Prefix request with protocol frames
      # Frame 0: empty (REQ emulation)
      # Frame 1: "MDPCxy" (six bytes, MDP/Client x.y)
      # Frame 2: Service name (printable string)
      request = [MDP::C_CLIENT, MDP::W_REQUEST, service, rid].concat(request)
      @client.send_strings request

      res = Array.new
      res << rid

      data = Array.new
      while 1 do
        chunk = _recv(timeout)
        data << chunk[4]
        break if chunk[0] == MDP::W_REPLY
      end

      res << data
      res
    end

    def _recv timeout
      items = @poller.poll(timeout)
      if items
        messages = []
        @client.recv_strings messages

        # header
        if messages.shift != MDP::C_CLIENT
          raise RuntimeError, "Not a valid MDP message"
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
      @client.setsockopt ZMQ::IDENTITY, "C" + (rand() * 10).to_s
      @client.connect @broker
      @poller.register @client, ZMQ::POLLIN
    end
  end
end
