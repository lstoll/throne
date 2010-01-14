require 'cgi'

class Throne::Document < Hashie::Dash
  class NotFound < StandardError; end
  
  class << self
    # Issue the subclass with an _id and _rev
    def inherited(klass)
      %w(_id _rev type disk_format_version update_seq doc_count instance_start_time purge_seq disk_size compact_running db_name doc_del_count).each do |property|
        klass.send(:property, property)
      end
    end
    
    # Create a new document and persist it to the database
    # @params [Hash] Properties to me persisted
    def create(properties)
      new(properties).save
    end
    
    # Get a document from the database
    # @param [String] docid the ID of the document to retrieve
    # @param [String] rev (optional) the revision of the document to retrieve
    # @return [Hash, nil] the document mapped to a hash, or nil if not found.
    def get(id, rev = nil)
      begin
        unless rev
          response = Throne::Request.get(:resource => id)
        else
          response = Throne::Request.get(:resource => id, :params => {:rev => revision})
        end

        new(response)
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
    
  # Persist a document to the database
  # @param [Hash] The document properties
  # @return [self]
  def save(doc = self.to_hash)
    if new_record?
      res = Throne::Request.post :resource => id
    else
      res = Throne::Request.put Hash.new(:resource => id).merge(doc)
    end
    
    self
  end

  # Delete a document
  # @param [String] Document ID
  def delete
    Throne::Request.delete(:resource => _id, :params => {:rev => (_rev || self.class.get(id)._rev)})
  end
  
  def <=>(other)
    [self._id, self._rev] <=> [other._id, other._rev]
  end
  
  # Is the record persisted to the database?
  # @returns [Boolean]
  def new_record?
    _id.nil?
  end
  
  def reload!
    self.class.get(id)
  end
  
  
  # id, alias to _id for convenience 
  def id
    _id
  end
  
  # revision, alias to _rev for convenience
  def revision
    _rev
  end
end