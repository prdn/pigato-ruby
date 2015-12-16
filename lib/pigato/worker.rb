require "#{File.dirname(__FILE__)}/base.rb"

class Pigato::Worker < Pigato::Base

  HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable

  def initialize broker, service, conf = {}
    @broker = broker
    @service = service

    @conf = {
      :autostart => false,
      :timeout => 2500,
      :heartbeat => 2500,
      :reconnect => 2500
    }
    
    @conf.merge!(conf)

    @liveness = 0
    @heartbeat_at = 0
    @reply_to = nil
    @reply_rid = nil
    @reply_service = nil
    
    init

    if @conf[:autostart]
      start
    end
  end
  
  def reply reply
    reply = [@reply_to, '', @reply_rid, '0'].concat([Oj.dump(reply)])
    send Pigato::W_REPLY, reply
  end

  def recv

    loop do

      iid = get_iid

      socket = get_socket 
      return nil if socket.nil? 

      @reply_rid = nil
      @reply_to = nil
      @reply_service = nil

      msg = socket.recv_message 

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
        send Pigato::W_HEARTBEAT
        @heartbeat_at = Time.now + 0.001 * @conf[:heartbeat]
      end

    end
  end

  def start 
    stop
    sock_create
    send Pigato::W_READY, @service
    super
    @liveness = HEARTBEAT_LIVENESS
    @heartbeat_at = Time.now + 0.001 * @conf[:heartbeat]
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
