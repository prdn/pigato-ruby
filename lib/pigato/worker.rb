class Pigato::Worker

  HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable

  def initialize broker, service
    @broker = broker
    @service = service
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
    send_to_broker Pigato::W_REPLY, reply
  end

  def recv
    loop do
      @reply_rid = nil
      @reply_to = nil
      @reply_service = nil

      msg = @socket.recv_message 

      if msg && msg.size 
        @liveness = HEARTBEAT_LIVENESS

        header = msg.pop.data
        if header != Pigato::W_WORKER
          puts "E: Header is not Pigato::WORKER"
          next
        end

        command = msg.pop.data

        case command
        when Pigato::W_REQUEST
          # We should pop and save as many addresses as there are
          # up to a null part, but for now, just save one...
          @reply_to = msg.pop.data
          @reply_service = msg.pop.data
          msg.pop # empty
          @reply_rid = msg.pop.data
          val = Oj.load(msg.pop.data) # We have a request to process
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
      @socket.close
    end
    if @ctx
      @ctx.destroy
    end

    @ctx = ZMQ::Context.new
    @socket = @ctx.socket ZMQ::DEALER
    @ctx.linger = 0
    @socket.identity = SecureRandom.uuid
    @socket.connect @broker
    @socket.rcvtimeo = @timeout;
    send_to_broker Pigato::W_READY, @service
    @liveness = HEARTBEAT_LIVENESS
    @heartbeat_at = Time.now + 0.001 * @heartbeat
  end

  def send_to_broker command, data = nil
    if data.nil?
      data = []
    elsif not data.is_a?(Array)
      data = [data]
    end

    data = [Pigato::W_WORKER, command].concat data
    msg = ZMQ::Message.new
    data.reverse.each{|p| msg.push(ZMQ::Frame(p))}
    @socket.send_message msg
  end
end
