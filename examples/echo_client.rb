#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"

client = PigatoClient.new('tcp://localhost:55555')
requests = 1000
d1 = Time.now
requests.times do |i|
  begin
    client.send('echo', 'Hello world')
  end
end
d2 = Time.now
puts "#{requests} requests/replies processed (#{(d2 - d1) * 1000} milliseconds)"
