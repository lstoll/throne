class Throne::Request
  class << self
    def get(resource = '', params = {})
      RestClient.get(build_uri(resource, params), options)
    end

    def delete(resource = '', params = {})
      RestClient.delete(build_uri(resource, params), options)
    end

    def put(resource = '', data = {})
      RestClient.put(build_uri(resource), data, options)
    end

    def post(resource = '', data = {})
      RestClient.post(build_uri(resource), data, options)
    end

    private
    def options
      { :accept_encoding  => "gzip, deflate" }
    end

    def build_uri(resource = '', params = nil)
      URI.join(Throne.base_uri, resource, paramify(params)).to_s
    end

    def paramify(params)
      if params && !params.empty?
        query = params.map do |k,v|
          v = Yajl::Encoder.encode(v) if %w{key startkey endkey}.include?(k.to_s) && (v.kind_of?(Array) || v.kind_of?(Hash))

          "#{k}=#{URI.escape(v.to_s)}"
        end

        "?" + query.join("&")
      else
        ''
      end
    end
  end
end