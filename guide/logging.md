# Logging with Traject

Logging is a useful tool that can allow you to see where things are
breaking or slowing down, keep track of progress, even warn you of
data this is substandard without stopping the indexing process.

## Uses for the logger.

The logger is available to the indexer simply as `logger`, which means
it's available in all your `each_record` and `to_field` routines as
well. You might use it to note what's going on outside of any indexing
routine, to note bad data, or to debug problems.

```ruby
# An example of logging in a configuration file

# Keep track of what jruby/java versions we're running
logger.info RUBY_DESCRIPTION

to_field 'full_title', extract_marc('245') do |record, accumulator, context|
  if accumulator.empty?
    logger.error "Record in position #{context.position} has no title"
  end
end

to_field 'my_weird_field', my_weird_macro do |rec, acc, context|
  logger.debug "my_weird_field values: #{acc.join('|')}"
end

```


## Settings for the default logger

By default, `traject` uses a
[Yell](https://github.com/rudionrails/yell) logger set to level `info`
and outputting to $stderr.

You can affect it with the following options:

* `log.file`: filename to send logging, or 'STDOUT' or 'STDERR' for those streams. Default STDERR

* `log.error_file`: Default nil, if set then all log lines of ERROR and higher will be _additionally_ sent to error file named.

* `log.format`: Formatting string used by Yell logger. https://github.com/rudionrails/yell/wiki/101-formatting-log-messages

* `log.level`:  Log this level and above. Default 'info', set to eg 'debug' to get potentially more logging info,
              or 'error' to get less. https://github.com/rudionrails/yell/wiki/101-setting-the-log-level

* `log.batch_size`: If set to a number N (or string representation), will output a progress line to INFO log, every N records.


## Using a different logger

If you want to use a different logging package to integrate with
existing code, you can set it in a configuration file. It just needs
to be able to responsd to the normal `#debug`, `#info`, `#warn`, and
`#error` messages.

Obviously, your own logger won't be checking the settings unless you
chooose to, so you'll have to set it all up "manually".

Make sure to set the logger in a configuration file with
`self.logger=`.


```ruby

# Set up a custom logger
require 'logger' # or you could use rjack_slf4j, logging, log4j, etc.
file = File.open('foo.log', 'w')
self.logger = Logger.new(file)

to_field 'id', extract_marc('001')

# ...and on and on
```


