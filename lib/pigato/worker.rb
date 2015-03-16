require "oj"
require "ffi-rzmq"
require "securerandom"

class Pigato::Worker

  HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable

  def initialize broker, service
    @broker = broker
    @service = service
    @context = ZMQ::Context.new(1)
    @poller = ZMQ::Poller.new
    @socket = nil # Socket to broker
    @heartbeat_at = 0 # When to send HEARTBEAT (relative to time.time(), so in seconds)
    @liveness = 0 # How many attempts left
    @timeout = 2500
    @heartbeat = 2500 # Heartbeat delay, msecs
    @reconnect = 2500 # Reconnect delay, msecs

    @reply_to = nil
    @reply_rid = nil
    @reply_service = nil

    reconnect_to_broker
  end
  
  def reply reply
    reply = [@reply_to, '', @reply_rid, '0'].concat([Oj.dump(reply)])
    send_to_broker Pigato::W_REPLY, reply, nil
  end

  def recv reply
    loop do
      @reply_rid = nil
      @reply_to = nil
      @reply_service = nil

      items = @poller.poll(@timeout) 
      if items
        msg = []
        @socket.recv_strings msg

        @liveness = HEARTBEAT_LIVENESS

        header = msg.shift
        if header != Pigato::W_WORKER
          puts "E: Header is not Pigato::WORKER"
          next
        end

        command = msg.shift

        case command
        when Pigato::W_REQUEST
          # We should pop and save as many addresses as there are
          # up to a null part, but for now, just save one...
          @reply_to = msg.shift
          @reply_service = msg.shift
          msg.shift # empty
          @reply_rid = msg.shift
          val = Oj.load(msg[0]) # We have a request to process
          return val 
        when Pigato::W_HEARTBEAT
          # do nothing
        when Pigato::W_DISCONNECT
          reconnect_to_broker
        else
        end
      else
        @liveness -= 1
        if @liveness == 0
          sleep 0.001*@reconnect
          reconnect_to_broker
        end
      end

      if Time.now > @heartbeat_at
        send_to_broker Pigato::W_HEARTBEAT
        @heartbeat_at = Time.now + 0.001 * @heartbeat
      end

    end
  end

  def reconnect_to_broker
    if @socket
      @poller.deregister @socket, ZMQ::DEALER
      @socket.close
    end

    @socket = @context.socket ZMQ::DEALER
    @socket.setsockopt ZMQ::IDENTITY, SecureRandom.uuid
    @socket.setsockopt ZMQ::LINGER, 0 
    @socket.connect @broker
    @poller.register @socket, ZMQ::POLLIN
    send_to_broker(Pigato::W_READY, @service, [])
    @liveness = HEARTBEAT_LIVENESS
    @heartbeat_at = Time.now + 0.001 * @heartbeat
  end

  def send_to_broker command, message=nil, options=nil
    if message.nil?
      message = []
    elsif not message.is_a?(Array)
      message = [message]
    end

    message = [Pigato::W_WORKER, command].concat message
    message = message.concat(options) if options
    
    @socket.send_strings message
  end
end
