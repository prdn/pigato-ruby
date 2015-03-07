#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"

client = PigatoClient.new('tcp://localhost:55555')
requests = 10
requests.times do |i|
  begin
    puts client.send('echo', 'Hello world')
  end
end

puts "#{requests} requests/replies processed"
