#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"

worker = Pigato::Worker.new('tcp://localhost:55555', 'echo')

loop do
  request = worker.recv 
  worker.reply request
end
