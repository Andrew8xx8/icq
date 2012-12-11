# Icq

The eventmachine-based implementation of the OSCAR protocol (AIM, ICQ)

## Installation

Add this line to your application's Gemfile:

    gem 'icq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install icq

## Usage

### Basic

Connects to ICQ as user 123456 and puts all recived messages

```ruby
  client = Icq::Client.new(uin: '123456', password: 'SECURE_PASSWORD')

  client.on_message do |username, text|
    puts username: username, text: text
  end

  client.start
```

### With configuration

```ruby
  Icq.configure do |config|
    config.server      = 'login.icq.com'
    config.port        = 5190
  end

  client = Icq::Client.new(uin: '123456', password: 'SECURE_PASSWORD')

  client.start
```

### Catch some errors

```ruby
  client = Icq::Client.new(uin: '123456', password: 'SECURE_PASSWORD')

  client.on_auth_error do |code, c|
    puts %s(auth-error) => '0x%02x' % code
  end

  client.on_connection_error do
    puts 'connection-error'
  end

  client.start
```

### Do anything on timer

Code in this callback will be executed every 2 seconds

```ruby
  client = Icq::Client.new(uin: '123456', password: 'SECURE_PASSWORD')

  client.on_timer(2) do 
    puts "Executing timer event: #{Time.now}"
  end

   client.start
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Inspired by
 
Hardcore EM-based code from here: https://github.com/devmod/em-oscar
