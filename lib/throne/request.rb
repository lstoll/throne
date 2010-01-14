require 'cgi'
class Throne::Request
  class << self    
    def get(request = {})
      Yajl::Parser.parse(RestClient.get(build_uri(request.delete(:resource), request.delete(:params)), options).to_s)
    end

    def delete(request = {})
      Yajl::Parser.parse(RestClient.delete(build_uri(request.delete(:resource), request.delete(:params)), options).to_s)
    end

    def put(request = {})
      Yajl::Parser.parse(RestClient.put(build_uri(request.delete(:resource), request.delete(:params)), Yajl::Encoder.encode(request), options).to_s)
    end

    def post(request = {})
      Yajl::Parser.parse(RestClient.post(build_uri(request.delete(:resource), request.delete(:params)), Yajl::Encoder.encode(request), options).to_s)
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
          v = Yajl::Encoder.encode(v) if %w{key startkey endkey}.include?(k.to_s) && (v.kind_of?(Array) || v.kind_of?(Hash))

          "#{k}=#{CGI.escape(v.to_s)}"
        end

        "?" + query.join("&")
      else
        ''
      end
    end
  end
end