# ♚ Throne

The king is here - on his couch, covered in rubies.

Simple library for working with CouchDB

## Caution!

This code is in _heavy_ development, in conjunction with a few development projects.
This means the API can and probably will change substantially over the next few
releases as we work out what fits best. You have been warned.


## Basic Usage

### Create a database object to work with. Will create the DB if it doesn't exist

    Throne.database = "blaster"
    Throne::Database.create

### Save a new document

    doc = Throne::Document.new(:first_name => "Arthur")
    doc.save
    
  or 
  
    Throne::Document.create(:first_name => "Arthur")

### Get a document

    Throne::Document.get(doc._id)
  
  * Note that _id is prefixed with _ just like it is in the database. id will give you the ruby object id.

### Save an existing document

    doc.save
    => true
    
  Say you want to add some properties in the process of the save
    
    doc.save(:king => true)
    => true

### Delete a document

    Throne::Document.destroy(doc._id)
    => true
  
  or, with your instance
  
    doc.destroy
    => true

### Destroy the database

    Throne::Database.destroy

## Json Parser

Throne uses `json_pure` as the default json parser, this allows for execution in environments like jruby, macruby and even windows. 
To use a C-based json parser (for production environments where proformance is important), install `yajl-ruby` with `gem install yajl-ruby`.

Throne will use Yajl when available and fall back to the `json_pure` implementation

## Links

* [Documentation](http://rdoc.info/projects/benschwarz/throne)


## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2009 Lincoln Stoll, Ben Schwarz, Badasses of the universe. See LICENSE for details.
