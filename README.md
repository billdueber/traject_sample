# Traject Sample Project

[`traject`](http://github.com/traject-project/traject/) is a jruby-based data transformation framework, designed
especially with an eye toward indexing MARC (library bibliographic) data into Solr.

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

That should install all the things you need, including `traject` itself. Then take a peek around.

* a simple, stand-alone configuration file that just pulls out id, title, and author from a set of MARC-XML records is at [simplest_possible_traject_config.rb](blob/master/simplest_possible_traject_config.rb)
* A much more extensive indexing file (extracted from the code used to index the HathiTrust catalog) is at [index.rb](blob/master/index.rb)
* sample configuration files that specify readers and writers are in the appropriate subdirectories.

Note that the file writer/solr.rb is just an example; you'll need to
customize it to actually talk to your solr installation.

And of course your actual indexing code will need to be producing the fields
expected by your own solr's `schema.conf`.


## Run #1: the simple indexing code

The file [simplest_possible_traject_config.rb](blob/master/simplest_possible_traject_config.rb) can be run on the included, 20-record MARC-XML file very simply as:

```
traject -c simplest_possible_traject_config.rb sample_data/20.xml 
```

That will read in the file, pull out the id/title/author, and dump the results using DebugWriter to a file named `debug_output.txt`

## Run #2: the exact same thing, but harder

We can do the exact same run, but show off using multiple configuration files, with:

```
traject -c reader/marc-xml.rb -c writer/debug.rb -c simplest_possible_traject_config.rb sample_data/20.xml 
```

Again, the data will be in `debug_output.txt`, as configured in the `writer/debug.rb` file.

## Run #3: Again, but with the more complex index file

This time we'll use the more complete sample index file in [index.rb](blob/master/index.rb)

```
traject -c reader/marc-xml.rb -c writer/debug.rb -c index.rb sample_data/20.xml 
```

Look through the `index.rb` file and the `debug_output.txt` files to see how the translation works.

## Running traject in general

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

