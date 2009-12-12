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


  private

  def c; RestClient; end
end
