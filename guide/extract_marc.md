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

In an application of the `extract_marc` macro (e.g., something like
`extract_marc('100ab')`), the first argument is used to specify what
values to extract.


### Extracting values from control (fixed) fields

For a fixed field, you can choose to extract either the whole value, a
single character, or a range of characters

```ruby
to_field 'id', extract_marc('001') # the whole value

to_field 'date_type_code', extract_marc('008[6]') # one character

to_field 'lang_code', extract_marc('008[35-37]') # three characters

```


## Extracting values from variable fields

A variable field specification has up to three components:

* a three-character tag ('245') -- required
* a two-character indicator specification between pipes ('245|*1|') -- optional
* list of subfields (resulting in something like '245|*1|abk' or '245abk') -- optional

Order is important: it must be tag, optionally followed by indicators,
optionally followed by subfields.

### The tag

The tag is the only required component. It must be *three characters*
long (so, use '020' to get an ISBN) and must *exactly* match the tag
in the record.

### The indicator spec

In some rare cases, you care what the specific indicators are on a
field. The indicator spec is *four characters* long -- pipe ('|'),
ind1, ind2, and a closing pipe.

Note that a space as one of the indicator characters *will only match
a space*. If you want to allow any value, use an asterisk ('*').

### The list of subfields

The list of subfields is simply a bunch of subfield characters all
mashed together (e.g., 'abcdefgkl69').

Values from those subfields will be, by default, joined together with
a single space.

You can change the join character with the `:separator=>` option to
`extract_marc`.

* Use `:separator=>"|"`, for example, to bring back pipe-separated results
* Explicitly specifying `:separator=>nil` results in *no* joining of the values -- each value is added as a separate entity.

To make that last point clear, the following are equivalent:

```ruby
# thes are the same
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

* `:separator` [default: ' ']. The string used to join the values of matched subfields together. You can set it to nil (`:separator=>nil`) to
diable joining values together. See below for special cases dealing with repeated subfields.
* `:first` [default: false]. Only return a single value. Unless your target solr field has `multiValued="true"` set, you probably want this in most cases.
* `:trim_punctuation` [default: false]. Trim off common trailing punctuation using [Marc21.trim_punctuation](http://rdoc.info/github/jrochkind/traject/Traject/Macros/Marc21.trim_punctuation). _Note that trimming punctuation is done after the application of a translation map, if any_!
* `:translation_map` [default: nil]. The name of a file used to create a Traject::TranslationMap object, that will in turn be used to map all the extracted values to something else. See the [Traject::TranslationMap documentation](http://rdoc.info/github/jrochkind/traject/Traject/TranslationMap) for more information.
* `:default` [default: nil]. Provide a default value for cases when the extractor returns nothing. Note that this happens *after* the application of the translation map (which may include its own default value).
* `:allow_duplicates` [default: false]. Allow duplicate values to be passed through; otherwise duplicates are automatically removed.
* `:alternate_script` [default: `:include`]. How to deal with linked 880 fields that contain alternate scripts. Default is to include them when they match a passed spec (e.g., if your spec is '245ab', it will include any 880s paired with the title field as well). Possible values are
  * `:include` (default) Include values in alternate scripts
  * false Don't include values alternate scripts
  * `:only` Only include valus from the linked fields

## Dealing with repeated subfields and the `:separator`

It's often the case that you want repeated subfields to be treated as
different values. For example, the 043a (language code) is repeatable,
but you don't want to stick all those values together; you want each
value to be individually translated into an English representation of
that language code.

`extract_marc` implements a special case for this. If you specify
exactly one subfield, and if that subfield is repeated in the field
being analyzed, the values in that repeated subfield will *not* be
joined together by the `:separator`.

To override this special case, you can specify the same subfield twice
in your spec (e.g., '043aa')

The rules for when values from multiple matched subfieds are joined
with the `:separator` value are as follows:

1. *SPECIAL CASE*: If you specify `:separator=>nil`, values are never joined no matter what, and you'll get one value for each matching subfield.
2. If you don't specify any subfields (e.g., '245'), it's treated as if you specified _all_ the subfields and all the
subfield values are joined and returned as a single string (except see #1)
3. If you explicitly specify multiple subfields (e.g., '245ab'), the values of all matching subfields will be joined and
returned as a single string (except see #1)
4. *SPECIAL CASE*: If you specify _exactly one subfield_ (e.g., '633a'), you'll get one value for each matching subfield
(i.e. usually a single value, but if the one subfield you're looking for is repeated, you'll get multiple values)
5. If you actually _want_ the values of a repeated subfield to be joined by the `:separator` in the case where you're
only specifying a single subfield, you can force the matter by specifying the subfield twice, e.g.,
'633aa', but again see #1, above.

So, given a record with exactly one field

     999 $a one $b two $a three

 ...we'd get the following:

~~~ruby
# record has a single field:
#     999 $a one $b two $a three

extract_marc('999')                    #=> ["one two three"]       (rule #2, one value)
extract_marc('999', :separator=>nil)   #=> ['one', 'two', 'three'] (rule #1, multiple values)
extract_marc('999ab')                  #=> ["one two three"]       (rule #3, one value)
extract_marc('999a')                   #=> ['one', 'three']        (rule #4, multiple values)
extract_marc('999b')                   #=> ['two']                 (rule #4, but there's one matching subfield)
extract_marc('999aa')                  #=> ["one three"]           (rule #5, one value)
extract_marc('999aa', :separator=>nil) #=> ['one', 'three']        (rule #1, multiple values)

# Note the effect of the special case in the following.
# The first part of the spec ('999ab') gets the default separator, a single space. The
# second part gets the special case as explained in #4, above.

extract_marc('999ab:999a')              #=> ["one two three", "one", "three"]
~~~


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
  # get rid of any string that doesn't seem to hold an 'edited by'
  accumulator.reject!{|val| val !~ /edited by/i}
  
  # pull out the editors we can find
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
