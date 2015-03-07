#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"

worker = PigatoWorker.new('tcp://localhost:55555', 'echo')
reply = nil

loop do
  request = worker.recv reply
  worker.reply request
end
