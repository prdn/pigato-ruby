class Pigato::Base

  @@sockets = {}
  @@mtxs = {}
  @@mtx = Mutex.new

  def init 
    @iid = SecureRandom.uuid
  end
 
  def get_thread_id
    tid = get_proc_id() + "#" + Thread.current.object_id.to_s
    tid
  end

  def get_proc_id
    pid = "#" + Process.pid.to_s
    pid
  end

  def get_iid 
    iid = get_thread_id + '#' + @iid
    iid
  end

  def get_socket
    socket = @@sockets[get_iid]
    socket
  end

  def get_mtx
    tid = get_thread_id

    if @@mtxs[tid].nil?
      @@mtxs[tid] = Mutex.new
    end 

    return @@mtxs[tid]
  end

  def sock_create
    @@mtx.synchronize {
      pid = get_proc_id()
 
      ctx = ZMQ::context
      if ctx == nil then
        ctx = ZMQ::Context.new
        ctx.linger = 0
      end

      socket = ctx.socket ZMQ::DEALER
      socket.identity = SecureRandom.uuid
      socket.connect @broker

      if !@conf[:timeout].nil? then
        socket.rcvtimeo = @conf[:timeout];
      end

      @@sockets[get_iid] = socket
    }
  end
  
  def sock_close
    @@mtx.synchronize {
      pid = get_proc_id()

      iid = get_iid

      socket = @@sockets[iid]
      if socket
        begin
          socket.close
        rescue
        end
        @@sockets.delete(iid)
      end
    }
  end

  def start
    @active = 1
  end

  def stop
    @active = 0
  end

end 
