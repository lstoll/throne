# Defines rake tasks for managing databases and views.
#
# Requires either a SERVER_URL or DB_URL defined as an environment variable.
# If SERVER_URL is set the database path is inferred from the directory the files
# are stored in, if DB_URL is set that database is explicitly used, 
# overriding the name of the folder/task. 
class Throne::Tasks
  # Injects rake tasks for loading and dumping data from databases.
  # @param [String] base_path the path where design docs are stored
  def self.inject_data_tasks(base_path)
    namespace :throne do
      namespace :load_data do
        dirs_in_path(base_path).each do |dir, fulldir|
          desc "Loads data for database #{dir}"
          task dir.to_sym do
            load_data_for_database(url(dir), fulldir)
          end
        end

        desc "load all dbs"
        task :all => dirs_in_path(base_path)
      end
      namespace :dump_data do
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
  end

  # This will inject Rake tasks for loading design docs into the DB
  # The docs should be layed out in the following format:
  # base_path/
  # |-- <db name>
  #      `-- <design doc name>
  #          |-- lists
  #          |   `-- statuses
  #          |       `-- list.js
  #          `-- views
  #              `-- statuses
  #                  |-- map.js
  #                  `-- reduce.js 
  #
  # @param [String] base_path the path where design docs are stored
  def self.inject_design_doc_tasks(base_path)
    namespace :throne do
      namespace :push_design do
        dirs_in_path(base_path).each do |dir, fulldir|
          desc "pushes designs for database #{dir}"
          task dir.to_sym do
            load_design_documents(url(dir), fulldir)
          end
        end

        desc "push all designs"
        task :all => dirs_in_path(base_path)
      end
    end
  end

  # Injects tasks to create and delete databases
  def self.inject_database_tasks(base_path)
    namespace :throne do
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
  # base_path/
  # |-- <db name>
  #      `-- <design doc name>
  #          |-- lists
  #          |   `-- statuses
  #          |       `-- list.js
  #          `-- views
  #              `-- statuses
  #                  |-- map.js
  #                  `-- reduce.js 
  # @param [String] db_url the url of the database to load the data in to
  # @param [String] source_path the path to search for .yml and .json files
  def self.load_design_documents(db_url, source_path)
    # for each folder in base path, create a new design doc key
    # create a lists key
    # for each path in lists, add a key with the folder name
    # inside this, there is a key called list, with the contents of the list function
    # views is the same, except with a map and reduce function
    Dir.glob(File.join(source_path, '*')).each do |doc_path|
      doc_name = File.basename(doc_path)
      doc = {'lists' => {}, 'views' => {}}
      Dir.glob(File.join(doc_path, 'lists', '*')) do |list_path|
        list_name = File.basename(list_path)
        doc['lists'][list_name] = {}
        listfn = File.join(list_path, 'list.js')
        doc['lists'][list_name] = 
            File.read(listfn) if File.exists?(listfn)
      end
      Dir.glob(File.join(doc_path, 'views', '*')) do |view_path|
        view_name = File.basename(view_path)
        doc['views'][view_name] = {}
        mapfn = File.join(view_path, 'map.js')
        reducefn = File.join(view_path, 'reduce.js')
        doc['views'][view_name]['map'] =
            File.read(mapfn) if File.exists?(mapfn)
        doc['views'][view_name]['reduce'] =
            File.read(reducefn) if File.exists?(reducefn)
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
      puts "Design documents from #{source_path} loaded"
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
  def self.load_data_for_database(db_url, source_path)
    @db = Throne::Database.new(db_url)
    items = []
    doccount = 0
    # grab and parse all YML files
    Dir.glob(source_path + '/**/*.yml').each do |yml|
      items << YAML::load(File.open(yml))
    end
    # and json
    Dir.glob(source_path + '/**/*.json').each do |json|
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
      puts "#{doccount} document(s) loaded into database at #{@db.url}"
    end
  end

  def self.dump_docs_from_db(db, base_path, format)
    raise "You must specify a DB name to dump task[dbname]" unless db
    outdir = File.join(base_path, db)
    Dir.mkdir(outdir) unless File.exists?(outdir)
    @db = Throne::Database.new(url(db))
    docs = []

    @db.function('_all_docs') do |res|
      docs << @db.get(res['key']) unless res['key'].match(/^_/)
    end

    outfn = format == :json ? 'dump.json' : 'dump.yml'
    File.open(File.join(outdir, outfn), 'w') do |f| 
      if format == :json
        f.puts docs.to_json
      elsif format == :yml
        f.puts docs.to_yaml
      else
        raise("Internal Error - invalid dump format specified")
      end
    end
    puts "Data dumped to #{base_path + '/' + db + '/' + outfn}"
  end

  private

  def self.dirs_in_path(path)
    res = {}
    Dir.glob(path + '/*').each do |fn|
      res[File.basename(fn)] = fn if File.directory?(fn) 
    end
    res
  end

  def self.url(dbname)
    if dburl = ENV['DB_URL']
      return dburl
    elsif svrurl = ENV['SERVER_URL']
      return svrurl + '/' + dbname
    else
      raise("You must provide a SERVER_URL or DB_URL")
    end
  end

end
