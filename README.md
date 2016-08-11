# PIGATO-RUBY - Ruby Client / Worker for PIGATO

[![PIGATO](http://ardoino.com/pub/pigato-ruby-200.png)](https://github.com/prdn/pigato-ruby)

**PIGATO - an high-performance microservices framework based on ZeroMQ**

PIGATO aims to offer an high-performance, reliable, scalable and extensible service-oriented framework supporting multiple programming languages: Node.js/Io.js and Ruby.

* [Official PIGATO project page](http://prdn.github.io/pigato/)
* [Node.js and io.js broker/client/worker](https://github.com/prdn/pigato)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pigato'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pigato

## API

### Client
#### `Pigato::Client.new(addr, conf)`

**Example**

```
require "rubygems"
require "pigato"

client = Pigato::Client.new('tcp://localhost:55555', { :autostart => 1 })
client.request('echo', 'Hello world', { 'nocache' => 1 })
```

### Worker
#### `Pigato::Worker.new(addr, serviceName)`

**Example**

```
worker = Pigato::Worker.new('tcp://localhost:55555', 'echo')
worker.start
reply = nil

loop do
  request = worker.recv
  worker.reply request
end
```

## Usage

In order to run the example you need to run Node.js PIGATO example Broker from the [main project](https://github.com/prdn/pigato/tree/master/examples)

Example client/worker echo:

* `examples/echo_client.rb`
* `examples/echo_worker.rb`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pigato/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
