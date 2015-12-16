#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"
require 'thread'

def start
  ts = []

  (0..5).each do |tid|
    ts << Thread.new {
      client = Pigato::Client.new('tcp://127.0.0.1:55555')
      client.start

      requests = 10000
      d1 = Time.now
      requests.times do |i|
        begin
          client.request('echo', 'Hello world1')
        end
      end
      d2 = Time.now
      puts "#{requests} requests/replies processed (#{(d2 - d1) * 1000} milliseconds)"
    }
  end

  ts.each do |to|
    to.join
  end
end

(0..1).each do |pid|
  pid = fork do
    start
  end
end

Process.waitall
