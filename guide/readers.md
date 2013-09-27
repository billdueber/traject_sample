# Traject: Reading in MARC

## Picking a MARC Reader

You can tell `traject` which style of MARC reader you want to use by
specifying the class of the reader in several ways:

* on the command line with `-r <classname>`
* on the command line with `-s reader_class_name <classname>`
* in a configuration file by `provide "reader_class_name", "<classname>"`

For regular binary, utf-8 MARC files, the MarcReader and Marc4JReader
have similar performance characteristics (and solr is almost certainly
going to be your bottleneck anyway). For NJD/JSON, MarcReader is your
only option. For MARC-XML or non-utf8 binary marc, you'll probably
want to go with marc4j.

### `Traject::MarcReader` 

[See the [sample configuration for MarcReader](../reader/marc.rb) in
the reader directory]


`Traject::MarcReader` is based on the stock [ruby-marc](http://github.com/ruby-marc/ruby-marc/)
reader class. By default, it instantiates a basic MARC21/unicode
binary reader, but can also read MARC-XML or marc-in-json.

Settings that affect `Traject::MarcReader` are:

* `marc_source.type` [default: "binary"]: the type of MARC file. Valid options are "binary" for binary MARC, "xml" for MARC-XML, and "json" (or its synonym 'ndj') for newline-delimited [marc-in-json](http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/).
* `marc_reader.xml_parser` [default: leave it up to the xml library]. Any valid XML reader option to pass to MARC::XMLReader. See [the source](https://github.com/ruby-marc/ruby-marc/blob/master/lib/marc/xmlreader.rb#L35) for all options, but really, the only one you want to use is 'nokogiri'.

### `Traject::Marc4JReader`

[See the [sample configuration for MarcReader for binary
marc](../reader/marc4j.rb) or [marc-xml](../reader/marc-xml.rb) in the
reader directory]

`Traject::Marc4JReader` uses the [marc4j](http://github.com/marc4j/marc4j) java package to parse the underlying MARC records into standard ruby-marc records. The marc4j reader is often faster (especially for XML) and offers character encoding conversion and MARC8 support (always ending up with utf-8, though).

Settings that affect the marc4j reader are:

* `marc_source.type` [default: "binary"]. Valid values are "binary" and "xml"
* `marc4j_reader.permissive` [default: true]. For binary files, use the permissive reader instead of the strict reader. 
* `marc4j_reader.source_encoding` [default: "BESTGUESS"]. See [the Traject::Marc4JReader source](https://github.com/jrochkind/traject/blob/master/lib/traject/marc4j_reader.rb#L30) for all possible values.`BESTGUESS` believes what's in the leader; you may also want to force to "UTF-8" or "MARC8"
* `marc4j_reader.jar_dir` The marc4j reader will first check to see if it appears that the marc4j `.jar` file has already been loaded. If not, it will load the jars in the directory referenced by this setting. As a last (but not bad) resort, it will load the marc4j jars packaged with the [ruby-marc-marc4j gem](https://github.com/billdueber/ruby-marc-marc4j).
* `marc4j_reader.keep_marc4j` [default: false]. If set to `true`, the underlying marc4j java object will be available as `record.original_marc4j`. Useful if and only if you have legacy java code to which you need to send a marc4j object.

