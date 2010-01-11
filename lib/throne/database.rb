class Throne::Database  
  class NameError < StandardError; end
  
  class << self
    def create
      Throne::Request.put
    rescue RestClient::RequestFailed => e
      super unless e.message =~ /412$/
    end
    
    def delete
      Throne::Request.delete
    end
  end
end
