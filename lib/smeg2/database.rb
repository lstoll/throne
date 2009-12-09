# Represents a connection to the database. Can be used standalone to talk
# to a couch instance manually, otherwise is used by the mapper.
class Smeg2::Database
  # Create a new instance, with the URL for the database to work with
  def initialize(url)
    @url = url
  end

  def create
    begin
      c.put @url, {}
    rescue RestClient::RequestFailed => e
      unless e.message =~ /412$/
        raise e
      end
    end
  end

  def delete!
    begin
      c.delete @url
    rescue RestClient::ResourceNotFound
    end
  end

  def create!
    delete!
    create
  end

  private

  def c; RestClient; end
end
