class Throne::Document < Hashie::Mash
  class NotFound < StandardError; end
  
  ## Class methods
  class << self   
    # Create a new document and persist it to the database
    # @params [Hash] Properties to be persisted
    def create(attributes = {})
      new.save(attributes)
    end
    
    # Get a document from the database
    # @param [String] docid the ID of the document to retrieve
    # @param [String] rev (optional) the revision of the document to retrieve
    # @return [Hash, nil] the document mapped to a hash, or nil if not found.
    def get(id, revision = nil)
      begin
        unless revision
          response = Throne::Request.get(:resource => id)
        else
          response = Throne::Request.get(:resource => id, :params => {:rev => _rev})
        end
        
        new.merge(response)
      rescue RestClient::ResourceNotFound
        raise NotFound
      end
    end
    
    # Remove a document from the database
    # @param [String] Document ID
    # @return [boolean]
    def delete(id)
      get(id).delete
    end
  end
  
  ## Instance methods
  
  def _id; self[:_id]; end
  def _rev; self[:_rev]; end
  
  # Persist a document to the database
  # @param [Hash] The document properties
  # @return [Hash]
  def save(attributes)
    self.merge!(attributes)
    
    if new_record?
      response = Throne::Request.post self.to_hash
    else
      data = {:resource => _id}.merge(self.to_hash)  
      response = Throne::Request.put data
    end
    
    self.merge!(response)
  end

  # Delete a document
  # @param [String] Document ID
  def delete
    Throne::Request.delete(:resource => _id, :params => {:rev => (_rev || self.class.get(_id)._rev)})
  end
  
  def <=>(other)
    [self._id, self._rev] <=> [other._id, other._rev]
  end
  
  # Is the record persisted to the database?
  # @returns [Boolean]
  def new_record?
    !key? :_id
  end
  
  # Reload data from couchdb
  # @returns [self]
  def reload!
    self.class.get(_id)
  end
  
  def method_missing(method, *args, &block)
    return self[method] if key? method
    
    match = method.to_s.match(/(.*?)([?=!]?)$/)
    case match[2]
    when "="
      self[match[1]] = args.first
    when "?"
      key?(match[1])
    else
      super
    end
  end
  
  def to_hash
    Hash.new(default).merge(self)
  end
end