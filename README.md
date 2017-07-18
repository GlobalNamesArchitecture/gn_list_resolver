# Global Names List Resolver

[![Gem Version][gem-badge]][gem-link]
[![Continuous Integration Status][ci-badge]][ci-link]
[![Coverage Status][cov-badge]][cov-link]
[![CodeClimate][code-badge]][code-link]
[![Dependency Status][dep-badge]][dep-link]

This gem crossmaps a checklist of scientific names to names from a data source
in [GN Index Resolver][gnindex].

Checklist has to be in a CSV format.

## Compatibility

This gem is compatible with Ruby versions higher or equal to 2.1.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gn_list_resolver'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install gn_list_resolver
```

## Usage

### Usage as a Web Application

see [gn\_crossmap\_web] project

### Usage from command line

```bash
# to see help
crossmap --help

# to compare with default source (Catalogue of Life)
crossmap -i my_list.csv -o my_list_col.csv

# to compare with other source (Index Fungorum in this example)
crossmap -i my_list.csv -o my_list_if.csv -d 5

# to use standard intput and/or output
cat my_list.csv | crossmap -i - -o - > output

# to keep only taxonID (if given) from original input
# no original fields will be kept without taxonID
cat my_list.csv | crossmap -i my_list.csv -s
```

### Usage as Ruby Library (API description)

#### `GnListResolver.run`

Compares an input list to a data source from [GN Resolver][resolver] and
writes result into an output file.

```ruby

opts = { input: input, output: output, data_source_id: 1 ,
         skip_original: true, alt_headers: [] }
GnListResolver.run(opts)
```

``input``
: (string) Either a path to a csv file with list of names, or "-" which
designates `STDIN`

``output``
: (string) Either a path to the output file, or "-" which designates `STDOUT`

``data_source_id``
: (integer) id of a data source from [GN resolver][resolver]

``skip_original``
: (boolean) if true only `taxonID` (if given) is preserved
from original data. Otherwise all original data is preserved. If there is no
``taxonID``, no original data will be preserved.

``alt_headers``
: (array) empty array by default. If `alt_headers` are not empty they are used
instead of the headers supplied with the file

``resolver_url``
: URL to globalnames' resolver. Default is ``http://resolver.globalnames.org``

#### `GnListResolver.logger=`

Allows to set logger to a custom logger (default is `STDERR`)

#### Usage Example

```ruby
require "gn_list_resolver"

# If you want to change logger -- default Logging is to standard error

GnListResolver.logger = MyCustomLogger.new

opts = { input: "path/to/input.csv", output: "path/to/output.csv,
         data_source_id: 5 , skip_original: true }
GnListResolver.run("path/to/input.csv", "path/to/output.csv", 5, true)

# if you want to use alternative headers instead of ones supplied in a file

opts = { input: "path/to/input.csv", output: "path/to/output.csv,
         data_source_id: 5 , skip_original: true,
         alt_headers: %w(taxonId, scientificName, rank) }
GnListResolver.run(opts)
```

If you want to get intermediate statistics for each resolution cycle use a
block:

```ruby
GnListResolver.run(opts) do |stats|
  puts stats
  puts "Matches:"
  stats[:matches].each do |key, value|
    puts "#{GnListResolver::MATCH_TYPES[key]}: #{value}"
  end
end
```

To trigger termination of the resolution before it is completed

```ruby
GnListResolver.run(opts) do
  # do something and then return STOP string from the block
  "STOP"
end
```

#### Intermediate stats format

|Field             |Description                                              |
|------------------|---------------------------------------------------------|
|status            |current phase: (init, ingested                           |
|total_records     |total number of names in original list                   |
|ingestion_start   |time when the reading from csv started                   |
|ingestion_span    |time of intermediate checkpoint of reading csv           |
|ingested_records  |number of ingested records at an intermediate checkpoint |
|resolution_start  |time when resolution of names started                    |
|resolution_stop   |time when resolution of names stopped                    |
|resolution_span   |time of intermediate checkpoint of resolving names       |
|resolved_records  |number of names already processed                        |
|last_batches_time |time required to process the last batch of names         |
|matches           |Distribution of processed data by match type (see below) |
|errors            |First 0-10 errors found during the csv file processing   |

#### Match types

Match types dictionary can be accessed with `GnListResolver::MATCH_TYPES` constant

| Match code | Match type                       |
|------------|----------------------------------|
|0           |No match                          |
|1           |Exact string match                |
|2           |Canonical form exact match        |
|3           |Canonical form fuzzy match        |
|4           |Partial canonical form match      |
|5           |Partial canonical form fuzzy match|
|6           |Genus part match                  |
|7           |Error in matching                 |

### Input file format

- Comma Separated File with names of fields in first row.
- Columns can be separated by **tab**, **comma** or **semicolon**
- At least some columns should have recognizable fields

`taxonID` `kingdom` `phylum` `class` `order` `family` `genus` `species`
`subspecies` `variety` `form scientificNameAuthorship` `scientificName`
`taxonRank`

#### simplest Example -- only scientificName

| scientificName                                          |
|---------------------------------------------------------|
| Animalia                                                |
| Macrobiotus echinogenitus subsp. areolatus Murray, 1907 |

#### taxonID and scientificName Example

    taxonID;scientificName
    1;Macrobiotus echinogenitus subsp. areolatus Murray, 1907
    ...

|taxonID | scientificName                                          |
|--------|---------------------------------------------------------|
|1       | Animalia                                                |
|2       | Macrobiotus echinogenitus subsp. areolatus Murray, 1907 |

#### Rank Example

    taxonID;scientificName;taxonRank
    1;Macrobiotus echinogenitus f. areolatus Murray, 1907;form
    ...

|taxonID | scientificName                                          | taxonRank |
|--------|---------------------------------------------------------|-----------|
|1       | Animalia                                                | kingdom   |
|2       | Macrobiotus echinogenitus subsp. areolatus Murray, 1907 | subspecies|

#### Family and Authorship Example

    taxonID;family;scientificName;scientificNameAuthorship
    1;Macrobiotidae;Macrobiotus echinogenitus subsp. areolatus;Murray, 1907
    ...

|taxonID | family        | scientificName            | scientificNameAuthorship|
|--------|---------------|---------------------------|-------------------------|
|1       |               | Animalia                  |                         |
|2       | Macrobiotidae | Macrobiotus echinogenitus | Murray                  |

#### Fine-grained Example

    TaxonId;kingdom;subkingdom;phylum;subphylum;superclass;class;subclass;cohort;superorder;order;suborder;infraorder;superfamily;family;subfamily;tribe;subtribe;genus;subgenus;section;species;subspecies;variety;form;ScientificNameAuthorship
    1;Animalia;;Tardigrada;;;Eutardigrada;;;;Parachela;;;Macrobiotoidea;Macrobiotidae;;;;Macrobiotus;;;harmsworthi;obscurus;;;Dastych, 1985

TaxonId|kingdom|subkingdom|phylum|subphylum|superclass|class|subclass|cohort|superorder|order|suborder|infraorder|superfamily|family|subfamily|tribe|subtribe|genus|subgenus|section|species|subspecies|variety|form|ScientificNameAuthorship
-------|-------|----------|------|---------|----------|-----|--------|------|----------|-----|--------|----------|-----------|------|---------|-----|--------|-----|--------|-------|-------|----------|-------|----|------------------------
136021|Animalia||Pogonophora||||||||||||||||||||||
136022|Animalia||Pogonophora|||Frenulata|||||||||||||||||||Webb, 1969
565443|Animalia||Tardigrada|||Eutardigrada||||Parachela|||Macrobiotoidea|Macrobiotidae||||Macrobiotus|||harmsworthi|obscurus|||Dastych, 1985

More examples can be found in [spec/files][files] directory

### Output file format

[Output][output] includes following fields:

Field                | Description
---------------------|-----------------------------------------------------------
taxonID              | original ID attached to a name in the checklist
scientificName       | name from the checklist
matchedScientificName| name matched from the GN Reolver data source
matchedCanonicalForm | canonical form of the matched name
rank                 | rank from the source (if it was given/inferred)
matchedRank          | corresponding rank from the data source
matchType            | what kind of match it is
editDistance         | for fuzzy-matching -- how many characters differ between checklist and data source name
score                | heuristic score from 0 to 1 where 1 is a good match, 0.5 match requires further human investigation

#### Types of Matches

The output fomat returns 7 possible types of matches:

1. **Exact string match** - The exact name was matched (but ignoring non-ascii characters)
2. **Exact match by canonical form of a name** - The canonical form of the name (a version of a scientific name that contains complete versions of the latin words, but lacks insertions of subtaxa, annotations, or authority information) was matched
3. **Fuzzy match by canonical form** - The canonical form gave a fuzzy (detecting lexical or spelling variations of a name using Tony Rees' algorithm TAXAMATCH) match
4. **Partial exact match by species part of canonical form** - The canonical form returned a partial but exact match
5. **Partial fuzzy match by species part of canonical form** - The canonical form returned a partial, fuzzy match
6. **Exact match by genus part of a canonical form** - The genus part of the canonical form of the species name returned an exact match
7. **[Blank]** - No match

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git
commits and tags, and push the `.gem` file to
[rubygems.org][rubygems]

## Contributing

1. Fork it ( ``https://github.com/GlobalNamesArchitecture/gn_list_resolver/fork`` )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Copyright

Authors -- [Dmitry Mozzherin][dimus], [Alexander Myltsev][alexander-myltsev]

Copyright (c) 2015-2017 [Dmitry Mozzherin][@dimus].
See [LICENSE][license] for details.

[gem-badge]: https://badge.fury.io/rb/gn_list_resolver.svg
[gem-link]: http://badge.fury.io/rb/gn_list_resolver
[ci-badge]: https://secure.travis-ci.org/GlobalNamesArchitecture/gn_list_resolver.svg
[ci-link]: http://travis-ci.org/GlobalNamesArchitecture/gn_list_resolver
[cov-badge]: https://coveralls.io/repos/GlobalNamesArchitecture/gn_list_resolver/badge.svg?branch=master
[cov-link]: https://coveralls.io/r/GlobalNamesArchitecture/gn_list_resolver?branch=master
[code-badge]: https://codeclimate.com/github/GlobalNamesArchitecture/gn_list_resolver/badges/gpa.svg
[code-link]: https://codeclimate.com/github/GlobalNamesArchitecture/gn_list_resolver
[dep-badge]: https://gemnasium.com/GlobalNamesArchitecture/gn_list_resolver.svg
[dep-link]: https://gemnasium.com/GlobalNamesArchitecture/gn_list_resolver
[gnindex]: http://index-api.globalnames.org/api
[rubygems]: https://rubygems.org
[dimus]: https://github.com/dimus
[alexander-myltsev]: https://github.com/alexander-myltsev
[license]: https://github.com/GlobalNamesArchitecture/gn_list_resolver/blob/master/LICENSE
[terms]: http://rs.tdwg.org/dwc/terms
[files]:  https://github.com/GlobalNamesArchitecture/gn_list_resolver/tree/master/spec/files
[output]: https://github.com/GlobalNamesArchitecture/gn_list_resolver/tree/master/spec/files/output-example.csv
[gnlist_resolver_gui]: https://github.com/GlobalNamesArchitecture/gnlist_resolver_gui
