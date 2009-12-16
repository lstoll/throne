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
end
