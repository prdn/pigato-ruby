#!/usr/bin/env ruby
require 'pry-remote'

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"
require 'thread'

client = Pigato::Client.new('tcp://localhost:55555')

#Process.daemon

#binding.remote_pry

client.start
client.start
requests = 1000
d1 = Time.now
requests.times do |i|
  begin
    client.request('echo', 'Hello world1')
  end
end
d2 = Time.now
puts "#{requests} requests/replies processed (#{(d2 - d1) * 1000} milliseconds)"
