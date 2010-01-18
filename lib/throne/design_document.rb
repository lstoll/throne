class Throne::DesignDocument
  class ListError < StandardError; end
  
  class << self
    def create(name, attributes = {})
      new(name).save(attributes)
    end
    
    def get(name)
      new(name)
    end
    
    # Execute a design document
    # @params [String] The major name of a design document. 
    # @params [Hash] :list, :view and :params options
    # :list is mapped to "_design/design-document-name/_list/list-name"
    # :view is mapped to "_design/design-document-name/_view/view-name"
    def execute(name, options = {})    
      if list?(options)
        document_path = "_list/#{options[:list]}/#{options[:view]}"
      elsif view?(options)
        document_path = "_view/#{options[:view]}"
      else
        document_path = name
      end
          
      Throne::Document.get("_design/#{document_path}", (options[:params] || {}))
    end
    
    def destroy(name)
      Throne::Document.destroy(name)
    end
    
    private
    def list?(options)
      raise ListError, "no view given" if options.key? :list and !options.key? :view
      options.key? :list and options.key? :view
    end
    
    def view?(options)
      options.key? :view and !options.key? :list
    end
  end
  
  attr_accessor :document
  
  def initialize(name)
    @name = name
    @document = Throne::Document.get("_design/#{name}")
  rescue Throne::Document::NotFound
    @document = Throne::Document.new
  end
  
  def save(attributes = {})
    document.save(attributes)
    self
  end
  
  def destroy
  end
end