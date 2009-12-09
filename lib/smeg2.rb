require 'json'
require 'rest_client'
require 'hashie'

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))

module Smeg2
  autoload :Document, 'smeg2/document'
  autoload :Tasks, 'smeg2/tasks'
  autoload :Database, 'smeg2/database'
end
