module PIGATO
  module PROTO
    #  This is the version of MDP/Client we implement
    C_CLIENT = "C"

    #  This is the version of MDP/Worker we implement
    W_WORKER = "W"

    #  MDP/Server commands, as strings
    W_READY        =  "1"
    W_REQUEST      =  "2"
    W_REPLY        =  "3"
    W_HEARTBEAT    =  "4"
    W_DISCONNECT   =  "5"
    W_REPLY_PARTIAL   =  "6"
  end
end
