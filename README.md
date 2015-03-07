# PIGATO-RUBY

* [Official PIGATO project page](http://prdn.github.io/pigato/) 
* [Node.js and io.js broker/client/worker](https://github.com/prdn/pigato)

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/pigato`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pigato'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pigato

## Usage
Example client/worker echo:

* `examples/echo_client.rb`
* `examples/echo_worker.rb`

In order to run the example you need to run Node.js PIGATO example Broker from the [main project](https://github.com/prdn/pigato/tree/master/examples)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pigato/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
