require 'rest_client'
require 'hashie'
require 'yajl'
module Throne
  autoload :Tasks,    'throne/tasks'
  autoload :Request,  'throne/request'
  autoload :Document, 'throne/document'
  autoload :Database, 'throne/database'
  autoload :DesignDocument, 'throne/design_document'
  
  class << self
    attr_accessor :server, :database
  end
  
  self.server = "http://127.0.0.1:5984"
end