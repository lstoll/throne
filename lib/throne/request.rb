require 'cgi'

begin
  require 'yajl'

  class Yajl::Encoder
    class << self
      alias_method :generate, :encode
    end
  end
  
  JsonParser = Yajl::Parser
  JsonEncoder = Yajl::Encoder  
rescue LoadError
  require 'json/pure'
  
  JsonParser = JSON
  JsonEncoder = JSON
end

class Throne::Request
  class << self    
    def get(request = {})
      JsonParser.parse(RestClient.get(build_uri(request.delete(:resource), request.delete(:params)), options).to_s)
    end

    def delete(request = {})
      JsonParser.parse(RestClient.delete(build_uri(request.delete(:resource), request.delete(:params)), options).to_s)
    end

    def put(request = {})
      JsonParser.parse(RestClient.put(build_uri(request.delete(:resource), request.delete(:params)), JsonEncoder.generate(request), options).to_s)
    end

    def post(request = {})
      JsonParser.parse(RestClient.post(build_uri(request.delete(:resource), request.delete(:params)), JsonEncoder.generate(request), options).to_s)
    end

    private
    def options
      { :accept_encoding  => "gzip, deflate" }
    end

    def build_uri(resource, params)
      raise Throne::Database::NameError, "no database name set" if Throne.database.nil?
      [Throne.server, Throne.database, (resource||'')].join('/') + paramify(params) 
    end

    def paramify(params = {})
      if params && !params.empty?
        query = params.map do |k,v|
          v = JsonEncoder.generate(v) if %w{key startkey endkey}.include?(k.to_s) && (v.kind_of?(Array) || v.kind_of?(Hash))

          "#{k}=#{CGI.escape(v.to_s)}"
        end

        "?" + query.join("&")
      else
        ''
      end
    end
  end
end