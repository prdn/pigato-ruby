#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"

client = Pigato::Client.new('tcp://localhost:55555', { :autostart => true })
requests = 1000
d1 = Time.now
requests.times do |i|
  begin
    client.request('echo', 'Hello world')
  end
end
d2 = Time.now
puts "#{requests} requests/replies processed (#{(d2 - d1) * 1000} milliseconds)"
