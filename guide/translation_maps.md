# Traject Translation Maps

A _translation map_ in traject refers to anything used to convert values from a raw form to a more useful form.

traject's `extract_marc` macro allows you to specify a `:translation_map=>filename` argument that will automatically find and use a translation map on the resulting data, or you can create one on your own within your indexing code and use it with impunity. 

Because traject is designed around running code, not parsing configuration files, it's easy to manipulate data on the fly.



## Traject::TranslationMap
In particular, traject provides [Traject::TranslationMap](http://rdoc.info/github/jrochkind/traject/Traject/TranslationMap) as a means by which you can find, create, cache, and maniuplate such maps. It provides:

* searching for files anyone on the load path in a `translation_maps` directory, allowing people to package up translation maps with their gems
* loading of ruby files (`.rb`, must evaluate to a hash or hash-like), `.yaml` files that mirror hashes, or simple java `.properites` files, automatically based on (and without specifying) the suffix.
* caching of the file off of disk, you can use `Traject::TranslationMap.new` with impunity in your indexing steps
* mechanisms to specify a default value and whether or not to pass through the original string
* agnosticsim with respect to evaluated ruby code. If what comes back provides `#[]` (hash lookup), it will work.

## Alternatives / add-ons 

Since loading a ruby file (with a `.rb` suffix) only requires that said file evaluates to an object with a `#[]` (hash-lookup) method, there are a variety of objects you can use:

* a regular hash, of course
* a case-insentive hash, perhaps like [this one](https://github.com/junegunn/insensitive_hash)
* a [MatchMap](https://github.com/billdueber/match_map), which implements pattern-matching logic similar to solrmarc's pattern files

