# Traject: Writing out values

The indexing stage of traject takes a variety of `to_field` and `each_record` indexing steps and a source record and produces a context object with an embedded `output_hash` hash of key=>value pairs. That, in turn, is handed off to a _writer_ which takes those key/value pairs and does something (hopefully) useful with them.

Traject was designed within a context of wanting to take MARC data and stuff it into a Solr backend, but that's not the only output mechanism that ships with traject, and writing your own is pretty simple.

The class of your writer is set with, e.g. `provide "writer_class_name", "Traject::DebugWriter"` in a configuration file or with the `-s writer_class_name=Traject::WhateverClass` command line option

## Traject::SolrJWriter

[See [writer/solr.rb](../writer/solr.rb) for an example]

The default output mechanism is to use [solrj](https://wiki.apache.org/solr/Solrj) to package up your output hash and send it to the specified solr installation. Using solrj under the covers allows us to use the very efficient solr binary format for streaming documents to the server, batch pushes, and basically take advantage of all the hard work that's gone into developing solrj in conjunction with solr itself.

It must be configured with the following settings:

* `solrj_writer.url`: The URL to your solr indexing endpoint root, e.g. "http://my.dev.machine:9033/catalog". Don't include the actual path to the update handler.
* `solrj_writer.parser_class_name` [default: whatever the solrj default is]: the name of the solrj parser to deal with responses.  Should be set to "XMLResponseParser" for older (1.x) solr versions, and "BinaryResponseParser" for more modern solrs.
* `solrj.jar_dir`: SolrJWriter needs to load Java .jar files with SolrJ. It will load from a packaged SolrJ, but you can load your own SolrJ (different version etc) by specifying a directory. All *.jar in directory will be loaded.
* `solr.version`: Set to eg "1.4.0", "4.3.0"; currently un-used, but in the future will control
  change some default settings, and/or sanity check and warn you if you're doing something
  that might not work with that version of solr. Set now for help in the future.
* `solrj_writer.batch_size` [default: 100]: size of batches that SolrJWriter will send docs to Solr in. Set to nil, 0, or 1, and SolrJWriter will do one http transaction per document, no batching.
* `solrj_writer.commit_on_close` [default false]: set to true to have SolrJWriter send an explicit commit message to Solr after indexing.
* `solrj_writer.server_class_name` [default "HttpSolrServer"] : String name of a solrj.SolrServer subclass to be used by SolrJWriter.
* `solrj_writer.thread_pool` [default: 1]: A thread pool is used for submitting docs to solr. Set to 0 or nil to disable threading. Set to 1, there will still be a single bg thread doing the adds. May make sense to set higher than number of cores on your indexing machine, as these threads will mostly be waiting on Solr. Speed/capacity of your solr might be more relevant. Note that processing_thread_pool threads can end up submitting to solr too, if solrj_writer.thread_pool is full. _Note: don't confuse this with the `processing_thread_pool` used to determine how many threads are used to turn raw records into output hashes._



## Traject::DebugWriter

[See [writer/debug.rb](../writer/debug.rb) for an example]

The `Traject::DebugWriter` produces a simple, human-readable output format that's also amenable to simple computer processing (e.g., with a simple `grep`). It's the output format used when you pass the `--debug-mode` switch to traject on the command line.

It recognizes the following settings:

* `writer_class_name`. Set to `Trajcet::DebugWriter` to set it up in the first place.
* `output_file` A filename to send output to instead of `$stdout`
* `debug_writer.idfield` [default: "id"] indicating which field in the  output_hash should be used to identify the record
* `debug_writer.format` [default: "%-12s %-25s %s"], a `sprintf` string with three placeholders for strings

The DebugWriter's output produces three-column output whose values are:

* The id of the record (really, whatever's in in the output_hash under the field specified in `debug_writer.idfield`)
* The field name (i.e., the first argument to `to_field` in your indexing code)
* A pipe-delimited list of values associated with that field name

If you accept all the defaults, you'll end up with something like this:

```
000003441    edition                   [1st ed.]
000001580    format                    Book | Online | Print
000001580    geo                       Great Britain
000001580    id                        000001580
000001580    isbn                      0631126902
000001580    language                  English
000001580    language008               eng
000001580    lccn                      74120936
000001580    mainauthor                Digby, Margaret, 1902-
000001580    oclc                      ocm00113131
000001580    pubdate                   1970
000001580    publisher                 Blackwell,
000001580    sdrnum                    sdr-wu1874523
000001580    title                     Agricultural co-operation in the Commonwealth.
```

It's easy to scan through and easy to grep through.

## Traject::JsonWriter

The JsonWriter outputs one JSON hash per record, separated by newlines.

It responds to the following:

* `writer_class_name`. Set to `Trajcet::JsonWriter` to set it up in the first place.
* `output_file` A filename to send output to instead of `$stdout`
* `json_writer.pretty_print` [default: false]: Pretty-print (e.g., include newlines, indentation, etc.) each JSON record instead of just mashing it all together on one line. The default, no pretty-printing option produces one record per line, easy to process with another program.
