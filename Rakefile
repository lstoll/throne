require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "throne"
    gem.summary = %Q{Simple CouchDB library}
    gem.description = %Q{Simple library for working with CouchDB. Avoids magic, keeps it simple.}
    gem.email = "lstoll@lstoll.net"
    gem.homepage = "http://github.com/lstoll/throne"
    gem.authors = ["Lincoln Stoll", "Ben Schwarz"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_dependency "rest-client", ">= 1.0.3"
    gem.add_dependency "hashie", ">= 0.1.5"
    gem.add_dependency "json_pure", ">= 1.2.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "throne #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
