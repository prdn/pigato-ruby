#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"

ts = []

[0, 1, 2, 3, 4, 5, 6].each do |tid|
  ts << Thread.new {
    worker = Pigato::Worker.new('tcp://127.0.0.1:55555', 'echo')
    worker.start

    loop do
      request = worker.recv
      if !request.nil?
        worker.reply request
      else
        sleep 0.1
      end
    end
  }
end

ts.each do |to|
  to.join
end
