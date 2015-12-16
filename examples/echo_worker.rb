#!/usr/bin/env ruby

require "rubygems"
require "#{File.dirname(__FILE__)}/../lib/pigato.rb"
#require "pigato"

def start
  ts = []

  (0..5).each do |tid|
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
end

(0..1).each do |pid|
  fork do
    start
  end
end

Process.waitall
