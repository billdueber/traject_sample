# Traject Example, 2013.09.24
# Bill Dueber
#
# A more-or-less real life example of a configuration file for indexing marc
# records, extracted from the HathiTrust catalog code.
#
# A different take on most of this stuff (and hence worth taking your
# time to look at) is packaged with traject at
# https://github.com/jrochkind/traject/blob/master/test/test_support/demo_config.rb



######################################################
######## Set the load path and load things up ########
######################################################


# I like to keep my local files under 'lib'. Adding this will also
# allow Traject::TranslationMap to find files in 
# './lib/translation_maps/'

$:.unshift  "#{File.dirname(__FILE__)}/../lib"


# Pull in the standard marc21 semantics, to get stuff like
# 'marc_sortable_title'. 'marc_publication_date', etc.
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# Ditto with the opinionated format classifier;
# this gives you the 'marc_formats' macro
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats


# set this depending on what you want to see
# and how often.
settings do
  store "log.batch_progress", 10_000
end


# It's a good idea to output exactly what you're running, so you know you're
# using the versions of java and jruby that you think you are.
#
# Note that you have access to a logger within this (and any) configuration 
# file. Don't be afraid to use it.

logger.info RUBY_DESCRIPTION


#############################################
#############################################
######### The indexing rules ################
#############################################
#############################################
#
# A traject configuration file -- like this one -- is just
# a bunch of ruby code. Because of this, you can require files,
# set variables, compute logic based on environment variables,
# etc. -- whatever you need.
#
# Special to the configuation files are four methods:
# * logger, which you've already seen, holds a logger
# * settings, also seen above, which allows you to pass settings to
#   the traject process. Use of settings is not limited to a single 
#   instance -- you can use it in every configuration file and override
#   stuff on the command line as well.
# * each_record(blk_or_lambda). each_record applies the code in the block or 
#   lambda to every record, but doesn't send anything to the writer.
#   The block (or lambda) should take two arguments: the record, and 
#   a Traject::Indexer::Context object (see below)
# * to_field 'field_name' block (or to_field("field_name", lambda)). The
#   block or lambda takes three arguments:
#   - the record
#   - an "accumulator", a ruby array-like into which you stuff values that
#     should be associated with the field_name. Generally you'll be putting
#     things into the accumulator, but you can also delete stuff from it,
#     transform it with #map! and it's ilk, and basically do anything you want.
#     At the moment your block/proc exits, though, every non-nil value (if any) 
#     currently in the accumulator will be stored in the context
#     as context.output_hash[field_name]
#   - A context (Traject::Indexer::Context) object. It provides a few conveniences:
#     - context.clipboard : a hash into which you can put intermediate values
#     - contet.output_hash : the has of field/values pairs that will eventually
#       be sent to the configured writer. You can mess with this to achieve 
#       arbitrary side-effect, although you don't want to make your code
#       too opaque.
#     - the method #skip! , which basically says, "yeah, let's stop processing
#       this one and never send anything to the writer."
#   
# It's entirely possible to never use the context (which is always optional
# to pass into the proc object). 





################################
###### Setup ###################
################################

# I like to set up a hash on the clipboard where I can stick stuff
# if I need to, knowing that it's not going to interfere with
# anything done by a macro or anything.

# each_record performs and action on every record/context pair that comes through,
# but doesn't set a field value or send anything to the writer. 
each_record do |rec, context|
  context.clipboard[:mysuff] = {}
end


# Get a marc4j record for conversion to XML, because the 
# stock ruby-marc XML serialization code is dog-slow
#
# First, define a converter *outside* of the block. This way I only create the
# object once, instead of once for every record!

marc_converter = MARC::MARC4J.new(:jardir => settings['marc4j_reader.jar_dir'])

# Go ahead and create a marc4j record object and hang onto it on the clipboard,
# since I know I'm gonna need it later.
each_record do |rec, context|
  context.clipboard[:marc4j] = {}
  context.clipboard[:marc4j][:marc4j_record] = marc_converter.rubymarc_to_marc4j(rec)
end



################################
###### CORE FIELDS #############
################################

# 'to_field' takes a name and either a block or a lambda, as described above.
# A macro (in this case, 'extract_marc') is simply some code that returns an 
# appropriate lambda that does the work that you want. 
#
# You're going to want to look at the docs for extract_marc for the full
# syntax.

# Note that we only want one id, so we'll take the first one
to_field "id", extract_marc("001", :first => true)


# Save binary marc, if that's your thing
# to_field 'fullrecord', serialized_marc(:format=>'binary')

# Or JSON
# to_field 'fullrecord', serialized_marc(:format=>'json')

# Or XML
# I use marc4j to convert to xml for storage. Note that
# I'm taking advantage of having filled the clipboard with a 
# :marc4j_record above, and knowing (because I used the
# marc_converter) that the marc4j libraries are all loaded up,
# so I'm comfortable calling org.marc4j.MarcXmlWriter.new
#
# You could also use serialized_marc(:format=>'xml'), but it's REALLY slow
# We need to address that in ruby-marc
to_field 'fullrecord' do |r, acc, context|
  xmlos = java.io.ByteArrayOutputStream.new
  writer = org.marc4j.MarcXmlWriter.new(xmlos)
  writer.setUnicodeNormalization(true)
  writer.write(context.clipboard[:marc4j][:marc4j_record]) 
  writer.writeEndDocument();
  acc << xmlos.toString
end


# Get the values for all the fields between 100 and 999
to_field "allfields", extract_all_marc_values(:from=>'100', :to=>'999')
  

################################
######## IDENTIFIERS ###########
################################


# Get the OCLC numbers (as defined in traject/macros/marc_semantics.rb)
# I want to let people find them in the 035z, too, but you may not.
to_field 'oclc', oclcnum('035a:035z')

# You can do the same sort of thing "by hand", like this.
# Find 035a that start with the string 'sdr'
sdr_pattern = /^sdr-/  # that's just regular ruby assignment to a regular variable
to_field 'sdrnum' do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached('035a') # use #cached, not #new
  acc.concat oh35a_spec.extract(record).grep(sdr_pattern) # only get the ones that match the pattern
end


# Get both 10- and 13-character ISBNs
# You could do this, and it'd work fine, but you're bettter off using
# the solr-side code at https://github.com/billdueber/solr-libstdnum-normalize
# so you're converting at solr query time as well.
#
# require 'library_stdnums'
#
# to_field 'isbn' do |record, acc|
#   isbn_spec = Traject::MarcExtractor.cached('020az', :separator=>nil) # 
#   vals = []
#   isbn_spec.extract(record).each do |v|
#     std = StdNum::ISBN.allNormalizedValues(v)
#     if std.size > 0
#       vals.concat std
#     else
#       vals << v
#     end
#   end
#   vals.uniq! # If it already has both a 10 and a 13, each will have generated the other
#   acc.concat vals
# end

to_field 'isbn', extract_marc('020a:020z')
to_field 'issn', extract_marc('022a:022l:022m:022y:022z:247x')
to_field 'isn_related', extract_marc("400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz")

to_field 'sudoc', extract_marc('086az')
to_field "lccn", extract_marc('010a')
to_field 'rptnum', extract_marc('088a')

################################
######### AUTHOR FIELDS ########
################################

to_field 'mainauthor', extract_marc('100abcd:110abcd:111abc')
to_field 'author', extract_marc("100abcd:110abcd:111abc:700abcd:710abcd:711abc")
to_field 'author2', extract_marc("110ab:111ab:700abcd:710ab:711ab")
to_field "authorSort", extract_marc("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab", :first=>true)
to_field "author_top", extract_marc("100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c")
to_field "author_rest", extract_marc("505r")


################################
########## TITLES ##############
################################

# For titles, we want with and without
to_field 'title',     extract_with_and_without_filing_characters('245abdefghknp', :trim_punctuation => true)
to_field 'title_a',   extract_with_and_without_filing_characters('245a', :trim_punctuation => true)
to_field 'title_ab',  extract_with_and_without_filing_characters('245ab', :trim_punctuation => true)
to_field 'title_c',   extract_marc('245c')

# For vernacular title (which I want separate for a variety of reasons), I want to make sure I specify 
# :only alternate_scripts
to_field 'vtitle',    extract_marc('245abdefghknp', :alternate_script=>:only, :trim_punctuation => true, :deduplicate=>true)

# Sortable title
to_field "titleSort", marc_sortable_title


to_field "title_top", extract_marc("240adfghklmnoprs0:245abfghknps:247abfghknps:111acdefgjklnpqtu04:130adfghklmnoprst0")
to_field "title_rest", extract_marc("210ab:222ab:242abhnpy:243adfghklmnoprs:246abdenp:247abdenp:700fghjklmnoprstx03:710fghklmnoprstx03:711acdefghjklnpqstux034:730adfghklmnoprstx03:740ahnp:765st:767st:770st:772st:773st:775st:776st:777st:780st:785st:786st:787st:830adfghklmnoprstv:440anpvx:490avx:505t")
to_field "series", extract_marc("440ap:800abcdfpqt:830ap")
to_field "series2", extract_marc("490a")

####################################
#### Callnumber / LCSH #############
####################################

to_field 'callnumber', extract_marc('050ab:090ab')
to_field 'broad_subject', marc_lcc_to_broad_category



################################
########### MISC ###############
################################

to_field "geo", marc_geo_facet
to_field "pubdate", marc_publication_date
to_field "format", marc_formats
to_field "publisher", extract_marc('260b:264|*1|:533c')
to_field "edition", extract_marc('250a')

to_field 'era', marc_era_facet

to_field 'language', marc_languages("008[35-37]:041a:041d:041e:041j")

# Various librarians like to have the actual 008 language code around
to_field 'language008', extract_marc('008[35-37]') do |r, acc|
  acc.reject! {|x| x !~ /\S/} # ditch values that are just spaces
  acc.uniq!
end



