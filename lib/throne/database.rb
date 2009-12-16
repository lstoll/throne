require 'cgi'

# Represents a connection to the database. Can be used standalone to talk
# to a couch instance manually, otherwise is used by the mapper.
class Throne::Database
  attr_reader :url

  # Create a new instance, with the URL for the database to work with
  # By default will create the database if it doesn't exist, pass false
  # as the second parameter to disable this.
  def initialize(url, autocreate = true)
    @url = url
    create_database if autocreate
  end

  # Creates this database, will not error if the database exists
  def create_database
    begin
      C.put @url, {}
    rescue RestClient::RequestFailed => e
      unless e.message =~ /412$/
        raise e
      end
    end
  end

  # deletes this database.
  def delete_database
    begin
      C.delete @url
    rescue RestClient::ResourceNotFound
    end
  end

  # gets a document by it's ID
  # 
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

  # creates/updates a document from a hash/array structure
  def save(doc)
    if id = doc['_id']
      res = C.put(@url + '/' + id, JE.encode(doc))
    else
      res = C.post(@url, JE.encode(doc))
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
  

  C = RestClient
  # This is so I can switch stuff later.
  JP = Yajl::Parser
  JE = Yajl::Encoder
end

# Extended string, to store the couch revision
class Throne::StringWithRevision < String
  # Couch revision ID
  attr_reader :revision

  def initialize(id, rev)
    @revision = rev
    super(id)
  end
end

# Extended array, to store the couch extra data
class Throne::ArrayWithFunctionMeta < DelegateClass(Array)
  # Offset field as returned by couch
  attr_reader :offset
  
  def initialize(array, offset)
    @offset = offset
    super(array)
  end
end

