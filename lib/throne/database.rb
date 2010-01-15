class Throne::Database  
  class NameError < StandardError; end
  
  class << self
    # Create the database (Throne.database)
    def create
      Throne::Request.put
    rescue RestClient::RequestFailed => e
      super unless e.message =~ /412$/
    end
    
    # Destroy the database (Throne.database)
    def destroy
      Throne::Request.delete
    end
  end
end
