require "json"
require "ffi-rzmq"

class PigatoWorker
  HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable

  def initialize broker, service
    @broker = broker
    @service = service
    @context = ZMQ::Context.new(1)
    @poller = ZMQ::Poller.new
    @worker = nil # Socket to broker
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
    reply = [@reply_to, '', @reply_rid, '0'].concat([reply.to_json])
    send_to_broker Pigato::W_REPLY, reply, nil
  end

  def recv reply
    loop do
      @reply_rid = nil
      @reply_to = nil
      @reply_service = nil

      items = @poller.poll(@timeout) 
      if items
        messages = []
        @worker.recv_strings messages

        @liveness = HEARTBEAT_LIVENESS

        header = messages.shift
        if header != Pigato::W_WORKER
          puts "E: Header is not Pigato::WORKER"
        end

        command = messages.shift

        case command
        when Pigato::W_REQUEST
          # We should pop and save as many addresses as there are
          # up to a null part, but for now, just save one...
          puts "REQUEST"
          @reply_to = messages.shift
          @reply_service = messages.shift
          messages.shift # empty
          @reply_rid = messages.shift
          return messages[0] # We have a request to process
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
    if @worker
      @poller.deregister @worker, ZMQ::DEALER
      @worker.close
    end

    @worker = @context.socket ZMQ::DEALER
    @worker.setsockopt ZMQ::IDENTITY, 'WRK01'
    @worker.setsockopt ZMQ::LINGER, 0 
    @worker.connect @broker
    @poller.register @worker, ZMQ::POLLIN
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
    
    @worker.send_strings message
  end
end
