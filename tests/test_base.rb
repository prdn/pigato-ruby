require 'test/unit'
require 'securerandom'
require 'rubygems'
require_relative "#{File.dirname(__FILE__)}/../../lib/pigato.rb"

class BaseTest < Test::Unit::TestCase

  def setup
    bhost = 'tcp://localhost:55555'
    @client = Pigato::Client.new(bhost, { :autostart => true })
    @ns = SecureRandom.uuid
    
    @wks = []    
    @wks << fork do
      worker = Pigato::Worker.new(bhost, @ns + 'echo')

      loop do
        reply = nil
        request = worker.recv reply
        worker.reply request
      end
    end

    @wks << fork do
      worker = Pigato::Worker.new(bhost, @ns + 'empty')

      loop do
        reply = nil
        request = worker.recv reply
        worker.reply nil
      end
    end
  end

  def teardown
    @wks.each do |wk|
      Process.kill 9, wk
      Process.wait wk
    end
  end

  def test0
    assert_equal('hello', @client.request(@ns + 'echo', 'hello'))
    h = { 'hello' => 'world' }
    assert_equal(h, @client.request(@ns + 'echo', h))
    a = ['a', 1, false]
    assert_equal(a, @client.request(@ns + 'echo', a))
    
    assert_equal(1, @client.request(@ns + 'echo', 1))
    
    assert_equal(nil, @client.request(@ns + 'empty', nil))
  end
end
