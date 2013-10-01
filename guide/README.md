# Guide to (parts of Traject)

`traject` is a set of tools and a programmers framework for getting and translation data, with a clear focus on pulling stuff out of library MARC records and pushing them into a solr index, such as those used by [Blacklight]() and [VUFind]().

This repository, along with this guide, serve to show a lot of the base functionality of `traject`.

## The horse's mouth

The _de facto_ and _de jure_ source of cannonical traject documentation is [the traject source and rdoc itself](https://github.com/jrochkind/traject). If there's a discrepency between these documents and those, assume those are correct (and please file a bug report!)

## The Guide: Table of Contents

* [Why consider traject instead of something else](why_traject.md)
* [Configuration files](configuration_files.md)
* [Reading in MARC](readers.md)
* [Writing things out](writers.md)
* [Logging](logging.md)
* [Actually indexing content: to_field and each_record](to_field_each_record.md)
* [Digging deep into `extract_marc`](extract_marc.md)
* [Transforming data with TranslationMaps](translation_maps.md)



