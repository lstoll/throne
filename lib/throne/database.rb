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
      c.put @url, {}
    rescue RestClient::RequestFailed => e
      unless e.message =~ /412$/
        raise e
      end
    end
  end

  # deletes this database.
  def delete_database
    begin
      c.delete @url
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
      JSON.parse(c.get(@url + '/' + docid + revurl))
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  # creates/updates a document from a hash/array structure
  def save(doc)
    if id = doc['_id']
      res = c.put(@url + '/' + id, doc.to_json)
    else
      res = c.post(@url, doc.to_json)
    end
    res = JSON.parse(res) 
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

    c.delete(@url + '/' + doc + '?rev=' + rev)
  end

  # runs a function by path, with optional params passed in
  def function(path, params = {}, &block)
    url = @url + '/' + path
    res = JSON.parse(c.get(paramify_url(url, params)))
    res = Throne::ArrayWithFunctionMeta.new(res['rows'], res['offset'])
    if block_given?
      # TODO - stream properly
      res.each do |i|
        yield i
      end
      nil
    else
      res
    end
  end

  private

  def paramify_url url, params = {}
    if params && !params.empty?
      query = params.collect do |k,v|
        v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
        "#{k}=#{CGI.escape(v.to_s)}"
      end.join("&")
      url = "#{url}?#{query}"
    end
    url
  end
  

  def c; RestClient; end
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

