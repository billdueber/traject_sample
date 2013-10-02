# Traject Translation Maps

A _translation map_ in traject refers to anything used to convert values from a raw form to a more useful form.

traject's `extract_marc` macro allows you to specify a `:translation_map=>filename` argument that will automatically find and use a translation map on the resulting data, or you can create one on your own within your indexing code and use it with impunity. 

Because traject is designed around running code, not parsing configuration files, it's easy to manipulate data on the fly.



## Traject::TranslationMap
In particular, traject provides [Traject::TranslationMap](http://rdoc.info/github/jrochkind/traject/Traject/TranslationMap) as a means by which you can find, create, cache, and maniuplate such maps. It provides:

* searching for files anyone on the load path in a `translation_maps` directory, allowing people to package up translation maps with their gems
* loading of ruby files (`.rb`, which must evaluate to a hash), `.yaml` files that mirror hashes, or simple java `.properites` files, automatically based on (and without specifying) the suffix.
* caching of the file off of disk, you can use `Traject::TranslationMap.new` with impunity in your indexing steps
* mechanisms to specify a default value and whether or not to pass through the original string
* agnosticsim with respect to evaluated ruby code. If what comes back provides `#[]` (hash lookup), it will work.

## Alternatives 

`Traject::TranslationMap` provides an easy way to deal with the most common translation case: simple key-value stores with optional default values.

If you need more complex translation, you can simply use `#map!` or its kin to work on the `accumulator` in a block (see [how to use a lambda _and_ a block](to_field_each_record.md#using-a-lambda-and-and-block)).

A quick example:

```ruby

# get a lousy language detection of any vernacular title

require 'whatlanguage'
wl = WhatLanguage.new(:all)
to_field 'vernacular_langauge', extract_marc('245', :alternate_script=>:only) do |rec, acc|
  # accumulator is already filled with the values of any 880s that reference a 245 because
  # of the call to #extract_marc
  acc.map! {|x| wl.language(x) }
  acc.uniq!
end
```



Within the block, you may also be interested in using:

* a case-insentive hash, perhaps like [this one](https://github.com/junegunn/insensitive_hash)
* a [MatchMap](https://github.com/billdueber/match_map), which implements pattern-matching logic similar to solrmarc's pattern files

