module Jira
  module Resource

    class Base

      attr_reader :client
      attr_accessor :expanded, :deleted, :attrs
      alias :expanded? :expanded
      alias :deleted? :deleted

      def initialize(client, options = {})
        @client   = client
        @attrs    = options[:attrs] || {}
        @expanded = options[:expanded] || false
        @deleted  = false
      end

      # The class methods are never called directly, they are always
      # invoked from a BaseFactory subclass instance.
      def self.all(client)
        response = client.get(rest_base_path(client))
        json = parse_json(response.body)
        json.map do |attrs|
          self.new(client, :attrs => attrs)
        end
      end

      def self.find(client, key)
        instance = self.new(client)
        instance.attrs[key_attribute.to_s] = key
        instance.fetch
        instance
      end

      def self.build(client, attrs)
        self.new(client, :attrs => attrs)
      end

      def self.rest_base_path(client)
        client.options[:rest_base_path] + '/' + self.endpoint_name
      end

      def self.endpoint_name
        self.name.split('::').last.downcase
      end

      def self.key_attribute
        :key
      end

      def self.parse_json(string)
        JSON.parse(string)
      end

      def respond_to?(method_name)
        if attrs.keys.include? method_name.to_s
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include? method_name.to_s
          attrs[method_name.to_s]
        else
          super(method_name)
        end
      end

      def rest_base_path
        # Just proxy this to the class method
        self.class.rest_base_path(client)
      end

      def fetch(reload = false)
        return if expanded? && !reload
        response = client.get(url)
        set_attrs_from_response(response)
        @expanded = true
      end

      def save(attrs)
        http_method = new_record? ? :post : :put
        begin
          response = client.send(http_method, url, attrs.to_json)
        rescue Jira::Resource::HTTPError => exception
          set_attrs_from_response(exception.response)
          save_status = false
        else
          set_attrs(attrs, false)
          set_attrs_from_response(response) #attach errors from Jira REST API if present
          save_status = true
        end
        @expanded = false
        save_status
      end

      def set_attrs_from_response(response)
        unless response.body.nil? or response.body.length < 2
          json = self.class.parse_json(response.body)
          set_attrs(json)
        end
      end

      # Set the current attributes from a hash.  If clobber is true, any existing
      # hash values will be clobbered by the new hash, otherwise the hash will
      # be deeply merged into attrs.  The target paramater is for internal use only
      # and should not be used.
      def set_attrs(hash, clobber=true, target = nil)
        target ||= @attrs
        if clobber
          target.merge!(hash)
          hash
        else
          hash.each do |k, v|
            if v.is_a?(Hash)
              set_attrs(v, clobber, target[k])
            else
              target[k] = v
            end
          end
        end
      end

      def delete
        client.delete(url)
        @deleted = true
      end

      def has_errors?
        respond_to?('errors')
      end

      def url
        if @attrs['self']
          @attrs['self']
        elsif @attrs[self.class.key_attribute.to_s]
          rest_base_path + "/" + @attrs[self.class.key_attribute.to_s].to_s
        else
          rest_base_path
        end
      end

      def to_s
        "#<#{self.class.name}:#{object_id} @attrs=#{@attrs.inspect}>"
      end

      def to_json
        attrs.to_json
      end

      def new_record?
        @attrs['id'].nil?
      end
    end

  end
end