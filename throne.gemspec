# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{throne}
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lincoln Stoll"]
  s.date = %q{2009-12-17}
  s.description = %q{Simple library for working with CouchDB. Avoids magic, keeps it simple.}
  s.email = %q{lstoll@lstoll.net}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc",
     "TODO"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "lib/tasks.rb",
     "lib/throne.rb",
     "lib/throne/database.rb",
     "lib/throne/document.rb",
     "lib/throne/tasks.rb",
     "spec/database_spec.rb",
     "spec/document_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/tasks_spec.rb",
     "throne.gemspec"
  ]
  s.homepage = %q{http://github.com/lstoll/throne}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple CouchDB library}
  s.test_files = [
    "spec/database_spec.rb",
     "spec/document_spec.rb",
     "spec/spec_helper.rb",
     "spec/tasks_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<hashie>, [">= 0"])
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<hashie>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<hashie>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
  end
end

