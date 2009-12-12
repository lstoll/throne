require 'cgi'

# Represents a connection to the database. Can be used standalone to talk
# to a couch instance manually, otherwise is used by the mapper.
class Smeg2::Database
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
  def get(docid)
    JSON.parse(c.get(@url + '/' + docid))
  end

  # creates/updates a document from a hash/array structure
  def save(doc)
    id = nil
    if id = doc['_id']
      c.put(@url + '/' + id, doc.to_json)
    else
      res = c.post(@url, doc.to_json)
      res = JSON.parse(res)
      id = res['id']
    end
    id
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

  # runs a design by path, with optional params passed in
  def design(path, params = {}, &block)
    url = @url + '/_design/' + path
    res = JSON.parse(c.get(paramify_url(url, params)))
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
