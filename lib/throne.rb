require 'yajl'
require 'rest_client'
require 'hashie'

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))

module Throne
  autoload :Document, 'throne/document'
  autoload :Tasks, 'throne/tasks'
  autoload :Database, 'throne/database'
  
  def self.server
    @@server ||= "http://localhost:5984"
  end
  
  def self.server=(address)
    @@server = address
  end
  
  def self.database
    @@database
  end
  
  def self.database=(name)
    @@database = name
  end
end
