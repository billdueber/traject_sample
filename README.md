# Traject Sample Project

This is a sample Traject project based on production code running the
indexing process for the [HatiTrust
catalog](http://www.hathitrust.org/). It covers much of the standard
functionality, but you'll still definitely want to read the `traject`
documentation for fuller explanations of what's going on and a
complete description of the out-of-the-box macros available.


## Getting started

You should just be able to clone this repository and then, **under
JRuby**, run

```
bundle install
```

That should install all the things you need, including `traject` itself. Then take a peek around the configuration files that specify readers and writers in the appropriate subdirectories, and take some time to look through the main [`index.rb`](index.rb) file, which contains a bunch of examples of how to extract and transform data from MARC files.



## The configuration files

Included are a few sample configuation files, showing both a good
subset of the options available and how you can split different
logic units into separate files.

You should take a minute to look at the reader/writer configuration
files to see one way of specifying configuration across multiple
files, and then walk through the index.rb file to see an example of
production-level code.

Note that the file writer/solr.rb is just an example; you'll need to
customize it to actually talk to your solr installation, and of course
your actual indexing code will need to be producing the fields
expected by your own solr's `schema.conf`.

## Running traject

`traject` takes a variety of options, many of which can be seen by simply running `traject --help`. Two of the most important are:

* `-c configfile`: Load a configuration file, such as those found under `reader/` and `writer/` in this repository
* `-s setting.name=value`: Provide a command-line equivalent to the `provide` command used to control settings in a configuration file.

Here are a few examples:

```
# Run a MARC binary file and get debug output to stdout
traject --debug-mode -c index.rb path/to/file.mrc

# Ditto, but put the debug information in a file
traject --debug-mode -c index.rb -s output_file=debug.out /path/to/file.mrc
# ...and look at debug.out to see what happened

# Use a configuration file to get better control over the debug information
traject -c index.rb -c writer/debug.rb /path/to/file.mrc

# Ditto, but read in a MARC-XML file
traject -c index.rb -c reader/marc-xml.rb -c writer/debug.rb /path/to/file.xml

# Dump results to a json file for later processing / examination
traject -c index.rb -c reader/marc-xml.rb -c writer/json.rb /path/to/file.xml

# Send things to solr, but turn logging to debug level
traject -c index.rb -c reader/marc-xml.rb -c writer/solr.rb  -s log.level=debug /path/to/file.xml

```

