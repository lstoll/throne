class Throne::DesignDocument
  class ListError < StandardError; end
  
  class << self
    def create(name, attributes = {})
      new(name).save(attributes)
    end
    
    # Get a design document
    # @params [String] The name of the design document
    # @return [Throne::DesignDocument] The design document
    def get(name)
      design = new(name)
      design.document = Throne::Document.get("_design/#{name}")
      design
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
    
    # Destroy the design document
    # @params [String] The name of the design document
    # @return [Boolean]
    def destroy(name)
      Throne::Document.destroy("_design/#{name}")
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
  
  # Create a new design document
  # @params [String] The major name of the design document
  def initialize(name)
    @name = name
    @document = Throne::Document.new
    @document._id = "_design/#{name}"
    @document
  end
  
  # Save the current design document
  # @params [Hash] Additional attributes to be saved
  def save(attributes = {})
    document.save(attributes)
    self
  end
  
  # Destroy the current design document
  # @params [Boolean]
  def destroy
    document.destroy
  end
end