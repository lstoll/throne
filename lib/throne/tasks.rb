# Defines rake tasks for managing databases and views.
class Throne::Tasks
  def self.inject_fixtures_tasks(base_path)
    namespace :throne do
      namespace :load_fixtures do
        dirs_in_path(base_path).each do |dir, fulldir|
          desc "Loads fixtures for database #{dir}"
          task dir.to_sym do
            @db = Throne::Database.new(url(dir))
            items = []
            # grab and parse all YML files
            Dir.glob(fulldir + '/**/*.yml').each do |yml|
              items << YAML::load(File.open(yml))
            end
            # and json
            Dir.glob(fulldir + '/**/*.json').each do |json|
              items << JSON.parse(File.open(json).read)
            end
            # load em up
            items.each do |item|
              if item.kind_of? Array
                item.each do |doc|
                  @db.save(doc)
                end
              elsif item.kind_of? Hash
                @db.save(item)
              else
                puts "There is something funky with the data for #{dir}"
              end
            end

            p items[0]
          end
        end

        desc "load all dbs"
        task :all => dirs_in_path(base_path)
      end
    end
  end

  def self.inject_design_doc_tasks(base_path)
    namespace :throne do
      desc "Pushes all design docs into the named db url"
      task :push_designs do
      end
    end
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
      raise("You must provide a SERVER_URL or DATABASE_URL")
    end
  end
end
