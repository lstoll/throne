require 'cgi'

class Throne::Document < Hashie::Mash
  class ImmutableProperty < StandardError; end
  
  class << self
    # Create a new document and persist it to the database
    def create(properties = {})
      new(properties).save
    end
    
    # Get a document from the database
    # Remove a document from the database
  end
    
  # Create a new document

  # Get a document from the database
  # @param [String] docid the ID of the document to retrieve
  # @param [String] rev (optional) the revision of the document to retrieve
  # @return [Hash, nil] the document mapped to a hash, or nil if not found.
  def get(docid, rev=nil)
    begin
      revurl = rev ? "?rev=#{rev}" : ""
      Hashie::Mash.new(JP.parse(C.get(@url + '/' + docid + revurl)))
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  # Persist a document to the database
  # @param [Hash] The document properties
  # @return [self]
  def save(doc = self.to_hash)
    if doc["_id"]
      res = Throne::Database.put _id, doc
    else
      res = Throne::Database.post nil, doc
    end
    res = JP.parse(res) 
    return nil unless res['ok']
    Throne::StringWithRevision.new(res['id'], res['rev'])
  end

  # deletes a document. Can take an object or id
  def delete(doc)
    if doc.kind_of? String
      rev = get(doc)['_rev']
    else
      rev = doc['_rev']
      doc = doc['_id']
    end

    C.delete(@url + '/' + doc + '?rev=' + rev)
  end

  # runs a function by path, returning an array of results.
  def function(path, params = {})
    items = []
    function_iter(path, params) {|i| items << i}
    items
  end


  # runs a function by path, invoking once for each item. 
  def function_iter(path, params = {}, &block)
    url = @url + '/' + path
    res = JP.parse(C.get(paramify_url(url, params)))
    res = Throne::ArrayWithFunctionMeta.new(res['rows'], res['offset'])
    if block_given?
      # TODO - stream properly, need to get objects.
      res.each do |i|
        yield Hashie::Mash.new(i)
      end
      nil
    else
      Hashie::Mash.new(res)
    end
  end

  private

  def paramify_url url, params = {}
    if params && !params.empty?
      query = params.collect do |k,v|
        v = JE.encode(v) if %w{key startkey endkey}.include?(k.to_s) && 
          (v.kind_of?(Array) || v.kind_of?(Hash))
        "#{k}=#{CGI.escape(v.to_s)}"
      end.join("&")
      url = "#{url}?#{query}"
    end
    url
  end
  
  # This is so I can switch stuff later.
  JP = Yajl::Parser
  JE = Yajl::Encoder
end