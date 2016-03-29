require "#{File.dirname(__FILE__)}/base.rb"

class Pigato::Worker < Pigato::Base

  HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable

  def initialize broker, service, conf = {}
    @broker = broker
    @service = service

    @conf = {
      :autostart => false,
      :timeout => 2500,
      :reconnect => 2500
    }
    
    @conf.merge!(conf)

    @heartbeat_at = Time.now - 1.minutes
    @liveness = 0
    @reply_to = nil
    @reply_rid = nil
    @reply_service = nil
  
    init

    if @conf[:autostart]
      start
    end

    Thread.new do
      client = Pigato::Client.new(broker, { :autostart => true })
      loop do
        @@mtx.lock
        begin
          if Time.now > @@global_heartbeat_at
            @@sockets_ids.each do |iid, sid|
              request = [Pigato::C_CLIENT, Pigato::W_HEARTBEAT, "worker", sid]
              msg = ZMQ::Message.new
              request.reverse.each{|p| msg.push(ZMQ::Frame(p))}
              client.send msg
            end
            @@global_heartbeat_at = Time.now + 2.5
          end
        rescue => e
          puts e
        end
        @@mtx.unlock
        sleep 2.5
      end
    end
  end
  
  def reply reply
    reply = [@reply_to, '', @reply_rid, '0'].concat([Oj.dump(reply)])
    send Pigato::W_REPLY, reply
  end
  
  def recv
    val = nil

    @reply_rid = nil
    @reply_to = nil
    @reply_service = nil

    iid = get_iid

    start if @@sockets[iid] == nil && @conf[:autostart]

    socket = get_socket
    return nil if socket.nil?

    socket.rcvtimeo = @conf[:timeout]

    msg = socket.recv_message

    if msg && msg.size
      @liveness = HEARTBEAT_LIVENESS

      header = msg.pop.data
      if header != Pigato::W_WORKER
        puts "E: Header is not Pigato::WORKER"
        return nil
      end

      command = msg.pop.data

      case command
      when Pigato::W_REQUEST
        @reply_to = msg.pop.data
        @reply_service = msg.pop.data
        msg.pop # empty
        @reply_rid = msg.pop.data
        val = Oj.load(msg.pop.data) 
      when Pigato::W_HEARTBEAT
      when Pigato::W_DISCONNECT
        start
      else
      end
    else
      @liveness -= 1
      if @liveness == 0
        sleep 0.001 * @conf[:reconnect]
        start
      end
    end
      
    if Time.now > @heartbeat_at
      send(Pigato::W_HEARTBEAT, ['', Oj.dump({ 'concurrency' => 1 })])
      @heartbeat_at = Time.now + 0.001 * (@conf[:timeout] * 1.5)
    end
    
    val
  end

  def start 
    stop
    sock_create
    send Pigato::W_READY, @service
    super
    @liveness = HEARTBEAT_LIVENESS
  end

  def stop
    sock_close
    super
  end

  def send command, data = nil
    if data.nil?
      data = []
    elsif not data.is_a?(Array)
      data = [data]
    end

    socket = get_socket

    data = [Pigato::W_WORKER, command].concat data
    msg = ZMQ::Message.new
    data.reverse.each{|p| msg.push(ZMQ::Frame(p))}
    socket.send_message msg
  end
end
