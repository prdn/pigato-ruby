#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"
require 'thread'

def start
  ts = []

  (0..10).each do |tid|
    ts << Thread.new {
      client = Pigato::Client.new('tcp://127.0.0.1:55555', { :autostart => true, :timeout => 20000 })

      requests = 1000
      success = 0
      d1 = Time.now
      requests.times do |i|
        begin
          res = client.request('echo', 'Hello world1')
          if res
            success += 1
          else
            puts "nil reply"
          end
        end
      end
      d2 = Time.now
      puts "#{success}/#{requests} requests/replies processed (#{(d2 - d1) * 1000} milliseconds)"
    }
  end

  ts.each do |to|
    to.join
  end
end

(0..4).each do |pid|
  pid = fork do
    start
  end
end

Process.waitall
