require 'yaml'

# Defines rake tasks for managing databases and views.
#
# Requires either a SERVER_URL or DB_URL defined as an environment variable.
# If SERVER_URL is set the database path is inferred from the directory the files
# are stored in, if DB_URL is set that database is explicitly used, 
# overriding the name of the folder/task. 
class Throne::Tasks
  # This will inject Rake tasks for loading design docs into the DB
  # The docs should be layed out in the following format:
  #
  # base_path/
  # |-- lib
  # |    `-- library.js
  # |-- data
  # |   `-- .json and .yml folders with seed data
  # |-- design
  # |   |-- lists
  # |   |   `-- statuses
  # |   |       `-- list.js
  # |   `-- views
  # |       `-- statuses
  # |           |-- map.js
  # |           `-- reduce.js 
  # |-- <db name>
  #     |-- lib
  #     |    `-- library.js
  #     |-- data
  #     |   `-- .json and .yml folders with seed data
  #     `-- design
  #          `-- <design doc name>
  #              |-- lists
  #              |   `-- statuses
  #              |       `-- list.js
  #              `-- views
  #                  `-- statuses
  #                      |-- map.js
  #                      `-- reduce.js 
  #
  # @param [String] base_path the path where design docs are stored
  def self.inject_tasks(base_path)
    namespace :throne do
      namespace :documents do
        namespace :load do
          databases_in_path(base_path).each do |dbname, fulldir|
            desc "Loads data for database #{dbname}, optionally into db"
            task dbname.to_sym, :db do |t, args|
              load_data_for_database(url(dbname, args), base_path, dbname)
            end
          end

          desc "load all dbs"
          task :all => databases_in_path(base_path)
        end
        namespace :dump do
          desc "Dump data for a database into a YAML file"
          task :yml, :db do |t, args|
            dump_docs_from_db(args.db, base_path, :yml)
          end

          desc "Dump data for a database into a JSON file"
          task :json, :db do |t, args|
            dump_docs_from_db(args.db, base_path, :json)
          end
        end
      end

      #design tasks
      namespace :design do
        namespace :push do
          databases_in_path(base_path).each do |dbname, fulldir|
            desc "pushes designs for database #{dbname}, optionally into db"
            task dbname.to_sym, :db do |t, args|
              load_design_documents(url(dbname, args), base_path, dbname)
            end
          end

          desc "push all designs"
          task :all => databases_in_path(base_path)
        end
      end

      # Db Tasks
      namespace :database do
        desc "Creates a database if it doesn't exist"
        task :createdb, :db do |t, args|
          get_db(args).create_database
          puts "Database at #{url(args.db)}"
        end

        desc "Deletes a database"
        task :deletedb, :db do |t, args|
          get_db(args).delete_database
          puts "Database at #{url(args.db)}"
        end

        desc "Deletes, creates and re-loads a database"
        task :rebuilddb, :db do |t, args|
          db = get_db(args)
          raise "you must specify the database name (task[db])" unless args.db
          db.delete_database
          # re-getting the object will create the DB
          db = get_db(args)
          # load design docs
          load_design_documents(db.url, File.join(base_path, 'design', args.db))
          # load data
          load_data_for_database(db.url, File.join(base_path, 'data', args.db))
          puts "Done."
        end
      end


      def self.get_db(args)
        args ? db = args.db : db = nil
        unless (ENV['SERVER_URL'] && args.db) || ENV['DB_URL']
          raise "You must specify DB_URL or task[db_name] and SERVER_URL"
        end
        Throne::Database.new(url(db))
      end
    end
  end

  # Injects all tasks. Related data files will be stores in base_path/data, and 
  # design docs in base_path/design
  #
  # @param [String] base_path path for db related files.
  def self.inject_all_tasks(base_path)
    inject_data_tasks(File.join(base_path, 'data'))
    inject_design_doc_tasks(File.join(base_path, 'design'))
    inject_database_tasks(base_path)
  end

  # Loads design documents into the database url, extracted from the source path
  # The docs should be layed out in the following format:
  #  `-- <design doc name>
  #      |-- lists
  #      |   `-- statuses
  #      |       `-- list.js
  #      `-- views
  #          `-- statuses
  #              |-- map.js
  #              `-- reduce.js 
  # @param [String] db_url the url of the database to load the data in to
  # @param [String] source_path the path to search for .yml and .json files
  def self.load_design_documents(db_url, base_path, database)
    # for each folder in base path, create a new design doc key
    # create a lists key
    # for each path in lists, add a key with the folder name
    # inside this, there is a key called list, with the contents of the list function
    # views is the same, except with a map and reduce function
    paths_for_item(base_path, database, 'design/*').each do |doc_path|
      doc_name = File.basename(doc_path)
      doc = {'lists' => {}, 'views' => {}}

      Dir.glob(File.join(doc_path, 'lists', '*')) do |list_path|
        list_name = File.basename(list_path)
        doc['lists'][list_name] = {}
        listfn = File.join(list_path, 'list.js')
        doc['lists'][list_name] = 
            inject_code_includes(base_path, database, listfn) if File.exists?(listfn)
      end

      Dir.glob(File.join(doc_path, 'views', '*')) do |view_path|
        view_name = File.basename(view_path)
        doc['views'][view_name] = {}
        mapfn = File.join(view_path, 'map.js')
        reducefn = File.join(view_path, 'reduce.js')
        doc['views'][view_name]['map'] =
            inject_code_includes(base_path, database, mapfn) if File.exists?(mapfn)
        doc['views'][view_name]['reduce'] =
            inject_code_includes(base_path, database, reducefn) if 
                File.exists?(reducefn)
      end
      # try to get the existing doc
      doc_id = "_design/#{doc_name}"
      db = Throne::Database.new(db_url)
      if svr_doc = db.get(doc_id)
        # merge
        doc = svr_doc.merge(doc)
      else
        doc['_id'] = doc_id
      end
      doc['language'] = 'javascript'
      db.save(doc)
      puts "Design documents from #{doc_path} loaded"
    end
    
    # try and get a document with the design name
    # if it's there, replace the lists and views keys with above data
    # otherwise, create a new document, set language to javascript
    # put document.
    # WIN 
  end

  # Loads data into the database url from the source path. Picks up .yml and .json
  # @param [String] db_url the url of the database to load the data in to
  # @param [String] source_path the path to search for .yml and .json files
  def self.load_data_for_database(db_url, base_path, database)
    @db = Throne::Database.new(db_url)
    items = []
    doccount = 0
    # grab and parse all YML files
    paths_for_item(base_path, database, 'data/**/*.yml').each do |yml|
      items << YAML::load(File.open(yml))
    end
    # and json
    paths_for_item(base_path, database, 'data/**/*.json').each do |json|
      items << JSON.parse(File.open(json).read)
    end
    # load em up
    items.each do |item|
      if item.kind_of? Array
        item.each do |doc|
          begin
            @db.save(doc)
          rescue RestClient::RequestFailed => e
            if e.message =~ /409$/
              puts "Duplicate document - this data has probaby already been loaded"
              doccount -= 1
            else
              raise e
            end
          end
          doccount += 1
        end
      elsif item.kind_of? Hash
        begin
          @db.save(item)
        rescue RestClient::RequestFailed => e
          if e.message =~ /409$/
            puts "Duplicate document - this data has probaby already been loaded"
            doccount -= 1
          else
            raise e
          end
        end
        doccount += 1
      else
        puts "There is something funky with the data for #{source_path}"
      end
    end
    puts "#{doccount} document(s) loaded into database at #{@db.url}"
  end

  def self.dump_docs_from_db(db, base_path, format)
    raise "You must specify a DB name to dump task[dbname]" unless db
    outdir = File.join(base_path, db, "data")
    FileUtils.mkdir_p(outdir) unless File.exists?(outdir)
    @db = Throne::Database.new(url(db))
    docs = []

    @db.function('_all_docs') do |res|
      docs << @db.get(res['key']) unless res['key'].match(/^_/)
    end

    outfn = format == :json ? 'dump.json' : 'dump.yml'
    File.open(File.join(outdir, outfn), 'w') do |f| 
      if format == :json
        f.puts JSON.pretty_generate(docs)
      elsif format == :yml
        f.puts docs.to_yaml
      else
        raise("Internal Error - invalid dump format specified")
      end
    end
    puts "Data dumped to #{base_path + '/' + db + '/' + outfn}"
  end

  private

  def self.inject_code_includes(base_path, database, file)
    res = ''
    File.open(file).each do |line|
      if line =~ /(\/\/|#)\ ?!code (.*)/
        if File.exists?(inc = File.join(base_path, database, 'lib', $2))
          res += File.read(inc)
        elsif File.exists?(inc = File.join(base_path, 'lib', $2))
          res += File.read(inc)
        else  
          raise "Include file #{$2} does not exist in lib/ or #{database}/lib"
        end
      else
        res += line
      end
    end
    res
  end
  
  # For the gives path, returns a list of database names and their full path.
  # exludes lib and our other dirs.
  def self.databases_in_path(path)
    res = {}
    Dir.glob(path + '/*').each do |fn|
      next if File.basename(fn) == 'lib'
      res[File.basename(fn)] = fn if File.directory?(fn) 
    end
    res
  end

  def self.url(dbname, args=nil)
    if svrurl = ENV['SERVER_URL']
      return svrurl + '/' + args.db if args && args.db
      return svrurl + '/' + dbname
    else
      raise("You must provide a SERVER_URL")
    end
  end

  # Given the base dir, the DB name and the item path we are after, get a list
  # of items. This includes global and DB spec.
  # e.g for item - data , designs, lib.
  def self.paths_for_item(base, database, item_glob)
    items = Dir.glob(File.join(base, item_glob))
    items.concat(Dir.glob(File.join(base, database, item_glob)))
  end

end
