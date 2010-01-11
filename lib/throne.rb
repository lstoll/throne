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
  
  class << self
    attr_accessor :server, :database
    
    def base_uri
      raise Database::NameError, "no database name set" if database.nil?
      URI.join(server, database).to_s
    end
  end
  
  self.server = "http://127.0.0.1:5984"
end