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
      desc "Pushes all design docs into the named db url"
      task :push_designs do
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
        # TODO
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

  # Injects rake tasks for loading and dumping data from databases.
  # @param [String] base_path the path where design docs are stored
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
