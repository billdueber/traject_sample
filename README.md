# Traject Sample Project

This is a sample Traject project based on production code running the indexing
process for the [HatiTrust catalog](http://www.hathitrust.org/). It covers much 
of the standard functionality, but you'll still definitely want to read the `traject`
documentation for fuller explanations of what's going on and a complete description
of the out-of-the-box macros available.

## Getting started

You should just be able to clone this repository and then, **under JRuby**, run

```
bundle install
```

## The configuration files

Included are a few sample configuation files, showing both a good subset of the options available
and how you can split different logic units into separate files.

You can run them as follows:

```
# Run a MARC binary file and get debug output to stdout
traject --debug-mode -c index.rb path/to/file.mrc

# Ditto, but put the debug information in a file
traject --debug-mode -c index.rb -s output_file=debug.out /path/to/file.mrc

# Dump the output to a debug file for futher processing / examination
traject -c index.rb -c writer/debug.rb /path/to/file.mrc

# Ditto, but read in a MARC-XML file
traject -c index.rb -c reader/marc-xml.rb -c writer/debug.rb /path/to/file.xml

