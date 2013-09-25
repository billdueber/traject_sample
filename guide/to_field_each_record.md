# Traject Indexing: to_field and each_record

Once you've set up a [reader](reader.md) and a [logger](logging.md) you're going to want to actually index some records. If you look in the [provided indexing code](../index.rb) you'll see a variety of uses of each.

## Record, Accumulator, and Context

`to_field` and `each_record` each take a Proc object (i.e., either a ruby block or a `lambda`). Any of the following signatures are valid:

```ruby

to_field 'field_name' { |record, accumulator|  ... }
to_field 'field_name' { |record, accumulator, context|  ... }

each_field { |record|  ... }
each_field { |record, context|  ... }

```

But whare are those three arguments?

### record

The `record` that gets passed to your Proc is just whatever is returned by the reader you're using. For the stock Traject readers, this is always a [MARC::Record](https://github.com/ruby-marc/ruby-marc/blob/master/lib/marc/record.rb) object, but `traject` itself doesn't care what it is so there's no reason one couldn't use Traject to index other types of data.

### accumulator

`to_field` (but not `each_record`) is also always passed an `accumulator`.

At the end of your `to_field` code, you need to make sure that the  `accumulator` holds "the stuff that's going to be sent to the writer". 

Whatever is in the accumulator when your code block exits gets stuffed onto the end of the `context.output_hash[field_name]` array. 


_The `accumulator` is just a reference to a ruby Array_. That means you can mess with it in whatever way you need to, **but you can't wholesale assign to it**! It's a reference, so you need to maniuplate it in place, generally with direct access, pushing/unshifting, and using methods like `#map!` and `#reject!`

This means there are a variety of common ruby patters that wont work:

```ruby

# None of this will work the way you hope

to_field('foo') {|rec, acc| acc = ["some constant"] } # WRONG!
to_field('foo') {|rec, acc| acc = rec.fields('020').map{|f| f['a']} } # WORNG!
to_field('foo') do |rec, acc|
  acc << 'bill'
  acc << 'dueber'
  acc = acc.map{|str| str.upcase}
end   # WRONG! WRONG! WRONG! WRONG! WRONG!  


# Instead, do this
to_field('foo') {|rec, acc| acc << "some constant" }
to_field('foo') extract_marc('020a')
to_field('foo') do |rec, acc|
  acc << 'bill'
  acc << 'dueber'
  acc = acc.map!{|str| str.upcase} #notice using "map!" not just "map"
end

```


### context

The context is a [Traject::Indexer::Context](https://github.com/jrochkind/traject/blob/master/lib/traject/indexer.rb#L366) object. It has the following useful properties and methods

* `context.clipboard` A hash into which you can stuff values that you want to pass from one indexing step to another. For example, if you go through a bunch of work to query a database and get a result you'll need more than once, stick the results somewhere in the clipboard.
* `context.position` The position of the record in the input file (e.g., was it the first record, seoncd, etc.). Useful for error reporting
* `context.output_hash` A hash mapping the field names (generally defined in `to_field` calls) to an array of values to be sent to the writer associated with that field. You *can*, but *probably should not*, mess around with this directly, doing stuff like changing the values or even adding new keys (and hence new field names). If doing stuff with side-effects is unavoidable, it's there for your use, but it exists outside any sanity checking, so you're on your own.
* `context.skip!(msg)` An assertion that this record should be ignored. No more indexing steps will be called, no results will be sent to the writer, and a `debug`-level log message will be written stating that the record was skipped.

## Use closures to avoid too much work

A _closure_ is a computer-science term that means "a piece of code that remembers all the variables that were in scope when it was created." In ruby, lambdas and blocks are closures. Method definitions are not, which most of us have run across much to our chagrin.

Within the context of `traject`, this means you can define a variable outside of a `to_field` or `each_record` block and it will be avaiable inside those blocks. And you only have to define it once.

Compare:

```ruby

# Create the transformer for every single record
to_field 'normalized_title' do |rec, acc|
  transformer = My::Custom::Format::Transformer.new # Oh no! I'm doing this for each of my 10M records!
  acc << transformer.transform(rec['245'].value)
end

# Create the transformer exactly once
transformer = My::Custom::Format::Transformer.new # Ahhh. Do it once.
to_field 'normalized_title' do |rec, acc|
  acc << transformer.transform(rec['245'].value)
end


```

### ...but don't worry about `Traject::TanslationMap`, `extract_marc`, or `Traject::MarcExporter.cached(spec)`

**NOTE** that the underlying files created by `Traject::TranslationMap` and the extractors created by `extract_marc(spec)` and calls to `Traject::MarcExtractor.cached(spec)` are both cached already, so there's no need to create those outside the block. In general, it's better to keep stuff inside the block so it's easier to see what's being used by which indexing step.

## Using a lambda _and_ and block

Traject macros (such as `extract_marc`) create and return a lambda. If you include a lambda _and_ a block on a `to_field` call, the latter gets the accumulator as it was filled in by the former.

A few quick examples:

```ruby

# Get the titles and lowercase them
to_field 'lc_title', extract_marc('245') do |rec, acc, context|
  acc.map!{|title| title.downcase}
end

# Build my own lambda and use it
mylam = lambda {|rec, acc|  acc << 'one'} # just add a constant
to_field('foo'), mylam do |rec, acc, context|
  acc << 'two'
end #=> context.output_hash['foo'] == ['one', 'two']


# You might also want to do something like this

to_field('foo'), my_macro_that_doesn't_dedup_ do |rec, acc|
  acc.uniq!
end

```


## Important things to know about indexing steps

* **All your `to_field` and `each_record` steps are run _in the order in which they were initially evaluated_**. That means that the order you call your config files can potentially make a difference if you're screwing around stuffing stuff into the context clipboard or whatnot.
* **`to_field` can be called multiple times on the same field name.** If you call the same field name multiple times, all the values will be sent to the writer.
* **Once you call `context.skip!(msg)` no more index steps will be run for that record**. So if you have any cleanup code, you'll need to make sure to call it yourself.
* **By default, `trajcet` indexing runs multi-threaded**. In the current implementation, the indexing steps for one record are *not* split across threads, but different records can be processed simultaneously by more than one thread. That means you need to make sure your code is thread-safe (or always set `processing_thread_pool` to 0). 


