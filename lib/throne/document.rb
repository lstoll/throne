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
    def destroy(id)
      get(id).destroy
    rescue Throne::Document::NotFound
      true
    end
  end
  
  ## Instance methods
  
  def initialize(attributes = nil, default = nil, &block)
    self[:ruby_class] = self.class.name
    super(attributes, default, &block)
  end
  
  def _id; self[:_id]; end
  def _rev; self[:_rev]; end
  
  # Persist a document to the database
  # @param [Hash] The document properties
  # @return [Hash]
  def save(attributes = {})
    if new_record?
      response = Throne::Request.post normalise(attributes).to_hash
    else
      data = {:resource => _id}.merge normalise(attributes).to_hash
      response = Throne::Request.put data
    end
    
    normalise(response)
  end

  # Remove self from the database
  # @param [String] Document ID
  # @return [Boolean]
  def destroy
    if Throne::Request.delete(:resource => _id, :params => {:rev => _rev}).key? "ok"
      true
    else
      false
    end
  end
  
  def <=>(other)
    [self._id, self._rev] <=> [other._id, other._rev]
  end
  
  # Is the record persisted to the database?
  # @returns [Boolean]
  def new_record?
    !key? :_id
  end
  
  private
  def normalise(hash)
    # Merge the hash with self
    merge!(hash)
    
    # Rename id and rev to _id and _rev
    %w(id rev).each do |attribute|
      self[:"_#{attribute}"] = delete attribute if key? attribute
    end
    
    # Remove ok
    delete("ok")
    self
  end
end