# Why use traject?

`traject` was born out of our collective experience with two other systems designed to do basically the same thing: Bob Haschart's very popular java suite [solrmarc](https://code.google.com/p/solrmarc/), and my (decidedly-less-popular) jruby-based [marc2solr](http://github.com/billdueber/marc2solr/). In it, Jonathan (and later I) incorporated features and anti-features derived from a variety of pain points associated with both.

## Why consider traject instead of marc2solr?

Because I'm the only one on the planet that ever used marc2solr, and I'm not supporting it anymore.

## Why consider traject intead of solrmarc?

_solrmarc_ is a java-based, configuration-driven system that has a tight integration with solr as its output and MARC as its input (hence the name), required java or beanshell code to extend, and is aimed, in many ways, at providing a powerful system for people who are comfortable editing configuration files but not as comfortable writing code.

There are many of us in the marc->solr community that fall outside of that sweet spot. We're comfortable programming (esp. in a dynamic language), want to be able to easily experiment with different indexing patterns. Some of us, admittedly, are less comfortable using Java (both its code and its build environments) and have been hampered by this when trying to use solrmarc.

To be clear: if solrmarc is working for you, there's no overpowering single reason to switch to traject. 

However, if you're just starting out, or looking at other options, there are things we think make traject appealing:

### Code

_solrmarc_ is necessarily built around _configuration_, what with Java being a static language and all. Because it's ruby all the way down, traject can allow us to make the easy things easy, and the hard things...not a whole lot harder. The [included indexing configuration](../index.rb) makes it clear just how easy it is to write blocks of code to do whatever needs doing.


### Macros Macros Macros

Traject is essentially a domain-specific language (DSL) for indexing. It ships with a variety of powerful macros for pulling data out of MARC21 records and transforming those data into whatever you want to stick into your index. The basic macro for [extracting data from MARC](extract_marc.md) has an expansive syntax that allows field-matching logic to take indicators into account, and a [variety of](https://github.com/jrochkind/traject/blob/master/lib/traject/macros/marc_format_classifier.rb) [basic](https://github.com/jrochkind/traject/blob/master/lib/traject/macros/marc21.rb) and  [opinionated semantic macros](https://github.com/jrochkind/traject/blob/master/lib/traject/macros/marc21_semantics.rb) make it easy to convert the MARC record into a storable format, extract and transform languages, formats, and dates, etc.

Writing your own macros is relatively painless if you have some ruby programming background, and the system is designed so that macros can easily be distrbuted as gems.


### Reader- and Writer-agnostic

The core traject logic takes a "record" from a reader and gives a key/value hash to a writer. This allows us to mix and match readers and writers, so long as your logic knows what it's expecting.

The readers that ship with traject all deal with MARC data, in binary, MARC-XML, or JSON format, and via ruby-marc or the excellent `marc4j` java package. The writers can push data to solr, of course, but also will spit out a file with JSON documents or a human-readable debug format. 


Building your own reader or writer is very simple, and we'd be happy to help out if there's something you need.

### Built with logging in mind

Every indexing step has access to a `logger` object, which allows you to keep track of failures, linting errors, etc. By default, we provide a [yell]() logger, but you can substitute anything that responds to `#debug`, `#info`, `#warn`, and `#error` (e.g., log4j, slf4j with a ruby wrapper, etc.).


### Leverages (J)Ruby

Traject is built on a base of ruby, specifically JRuby. This allows all the indexing code to be in concise, easy-to-understand and -extend ruby, but still allows the use of high-quality java packages. In particular, we use the `solrj` package (written and maintained by the solr group itself) to talk to solr, and optionally use `marc4j` to read MARC files.


### Fast

Traject went through an extensive profiling and benchmarking period where we figured out how to best approach readability/speed tradeoffs. For the vast majority of people, the bottleneck will be the solr installation you're pushing to, not the indexing code. 

Traject is also built from the ground up to allow multi-threaded use, which can significantly speed up indexing time (e.g., on my rather beefy hardware, I can index and push to solr about 800 records per second using five threads).


### Tests: Ours and yours

Traject has been developed in a test-driven manner and constantly run through continuous integration (thanks to Travis-CI). You can run the tests yourself if you get the [traject code](http://github.com/jrochkind/traject/) by simply doing the equivalent of `chruby jruby; bundle install; rake test`. 

And a quick look at [the tests included with the source code](https://github.com/jrochkind/traject/tree/master/test) will show you how to develop tests for your own code. Everything is modular, so writing tests is easy and running a test suite is fast. 

### Easy to contribute

Traject is simply ruby code, distrbuted as a gem and available on github. Creating your own macros (and gemifying them) is easy; as is contributing documentation or examples. 

