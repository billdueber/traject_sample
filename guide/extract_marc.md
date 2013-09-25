# Using `extract_marc`

If you're indexing MARC records, the `extract_marc` macro is almost certainly going to be the workhorse of your indexing routines. Understanding its powers and limitations will make your life easier.

Remember, all `extract_marc` overtly does is build and return a lambda (which you never need see) that sticks values into the accumulator. Under the hood, it builds and uses a `Traject::MarcExtractor` object, which you may find useful in your own macros or custom code.

You call `extract_marc` generically as

```ruby
to_field 'my_field', extract_marc(<specstring>, <options>)
  # or
to_field 'my_field', extract_marc(<specstring>, <options>) do |record, accumulator, context|
  # muck about with the accumulator, which already has the stuff
  # pulled out via extract_marc in it
end

```

The latter format is good for post-processing (say, eliminating uninteresting values) without going through the work of pulling things out of the record yourself.



## The specification syntax.

In an application of the `extract_marc` macro (e.g., something like `extract_marc('100ab')`), the first argument is used to specify what values to extract. 


### Extracting values from control (fixed) fields

For a fixed field, you can choose to extract either the whole value, a single character, or a range of characters

```ruby
to_field 'id', extract_marc('001') # the whole value

to_field 'date_type_code', extract_marc('008[6]') # one character

to_field 'lang_code', extract_marc('008[35-37]') # three characters

```


## Extracting values from variable fields

A variable field specification has up to three components:

* a three-character tag ('245') -- required
* a two-character indicator specification between pipes ('245|*1|') -- optional
* list of subfields ('245|*1|abk') -- optional

Order is important: it must be tag, optionally followed by indicators, optionally followed by subfields. 

### The tag

The tag is the only required component. It must be *three characters* long (so, use '020' to get an ISBN) and must *exactly* match the tag in the record.

### The indicator spec

In some rare cases, you care what the specific indicators are on a field. The indicator spec is *four characters* long -- pipe ('|'), ind1, ind2, and a closing pipe. 

Note that a space as one of the indicator characters *will only match a space*. If you want to allow any value, use an asterisk ('*'). 

### The list of subfields

The list of subfields is simply a bunch of subfield characters all mashed together (e.g., 'abcdefgkl69'). 

Values from those subfields will be, by default, joined together with a single space. 

You can change the join character with the `:separator=>` option to `extract_marc`. 

* Use `:separator=>"|"`, for example, to bring back pipe-separated results
* Explicitly specifying `:separator=>nil` results in *no* joining of the values -- each value is added as a separate entity.

To make that last point clear, the following are equivalent:

```ruby
to_field 'isbn', extract_marc("020az", :separator=>nil)
to_field 'isbn', extract_marc("020a:020z")
```


Things to note:

* If no subfields are explicitly listed, it means *all* subfields
* The order you specify the subfields in has *no effect*; values are always concatenated together in the order they appear in the actual field. 


### Passing in multiple field specifications

A single call to `extract_marc` can have multiple field specifications,  separated by colons or passed in as an array, or both:

```ruby

to_field 'issn', extract_marc('022a:022l:022m:022y:022z:247x')

# or use the %w syntax to make things more readable

to_field 'issn', extract_marc(%w[
  022a
  022l
  022m
  022y
  022z
  247x
])

# or mix and match to make clear that I'm targeting two different tags
to_field 'issn', extract_marc(%w[
  022a:022l:022m:022y:022z
  247x
])

```

## `extract_marc` options

In addition to the specification string (see above), `extract_marc` can take zero or more of the following options.

* `:first` [default: false]. Only return a single value. Unless your target solr field has `multiValued="true"` set, you probably want this in most cases.        
* `:trim_punctuation` [default: false]. Trim off common trailing punctuation using [Marc21.trim_punctuation](https://github.com/jrochkind/traject/blob/master/lib/traject/macros/marc21.rb#L178)
* `:translation_map` [default: nil]. A Traject::TranslationMap object that will be used to map all the extracted values to something else. See the [Traject::TranslationMap documentation](https://github.com/jrochkind/traject/blob/master/lib/traject/translation_map.rb) for more information.
* `:default` [default: nil]. Provide a default value for cases when the extractor returns nothing. Note that this happens *after* the application of the translation map (which may include its own default value).
* `:allow_duplicates` [default: false]. Allow duplicate values to be passed through; otherwise duplicates are automatically removed.
* `:alternate_script` [default: `:include`]. How to deal with linked 880 fields that contain alternate scripts. Default is to include them when they match a passed spec (e.g., if your spec is '245ab', it will include any 880s paired with the title field as well). Possible values are
  * `:include` (default) Include values in alternate scripts
  * false Don't include values alternate scripts
  * `:only` Only include valus from the linked fields

## Some examples

```ruby

# Just get the value out of the first 001
to_field 'id', extract_marc('001', :first=>true)

# Get the LCCN(s) out of any 010a fields
to_field 'lccn', extract_marc('010a')

# LC Callnumber from a couple locations
to_field 'callnumber', extract_marc('050ab:090ab')

# Publisher, including new RDA-style 264 indicator2 = 1
to_field "publisher", extract_marc('260b:264|*1|:533c')

# Just the vernacular title(s)
to_field 'vtitle',    extract_marc('245abdefghknp', :alternate_script=>:only, :trim_punctuation => true)

# A more complex example, manipulating the values in the accumulator
# A clearly misguided attempt to find editors. If only our data
# were this easy to work with!
#
# Included here because it's still a pretty good example of a complex 
# routine.

to_field 'editor', extract_marc('245c') do |record, accumulator, context|
  # move on if there's no editor
  accumulator.reject!{|val| val !~ /edited by/i}
  # pull out the editors. Well, some of them, anyway
  accumulator.map! do |val|
    match = /edited by (.+?)(;|\Z)/i.match(val)
    match && match[1]
  end
  
  # Remove any nils
  accumulator.compact!
  
  # Split on 'and' or '&'
  accumulator.map!{|val| val.split /(?:\sand\s|\s&\s)/ }
  # Flatten it out, in case we actually got any splits
  accumulator.flatten!
end


```
