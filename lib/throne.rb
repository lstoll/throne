require 'yajl'
require 'rest_client'
require 'hashie'

module Throne
  autoload :Tasks,    'throne/tasks'
  autoload :Request,  'throne/request'
  autoload :Document, 'throne/document'
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