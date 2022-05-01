require 'excon'
require_relative 'jsonapi'

module JSONAPI
  module Model
    # Supports mechanics of connecting with remote endpoint
    module Connectable
      extend ActiveSupport::Concern

      # Connection for accessing remote endpoints
      #
      # @return [Excon::Connection]
      def connection
        self.class.connection
      end

      # Parses JSONAPI reponses received
      #
      # @param response [Excon::Response] unparsed response from remote endpoint
      # @return [Hash]
      def parse(response, options: {})
        self.class.parse(response, options: options)
      end

    private

      def to_jsonapi
        serializer.new(self).serializable_hash.to_json
      end

      def serializer
        return @serializer if @serializer

        attribute_set = attributes
        raise Error::NoAttributesDefined if attribute_set.nil? || attribute_set.empty?

        type_to = type
        raise Error::NoSerializationTypeDefined unless type_to.present?

        @serializer ||= serializer_class(attribute_set, type_to)
      end

      def serializer_class(attributes, type)
        Class.new do
          include JSONAPI::Serializer

          set_type type if type

          attributes.each do |attribute_name|
            attribute attribute_name
          end
        end
      end

      def on_socket_error(error)
        self.class.on_socket_error(error)
      end

      # rubocop:disable Lint/UselessAccessModifier # bug in rubocop-rails; rails does support
      class_methods do
        def connection
          raise Error::NoHostDefined unless respond_to?(:host)

          @connection ||= Excon.new(host, headers: headers)
        end

        def parse(response, options: {})
          return unless response

          unless successful_status_code?(response.status)
            raise Error::RequestFailed.new(self, response)
          end

          Jsonapi.parse(response.body, options)
        end

        def on_socket_error(error)
          raise error unless error.respond_to?(:socket_error)
          raise error unless error.socket_error.is_a?(Errno::ECONNREFUSED)

          raise Error::UnavailableHost, host
        end

      private

        def headers
          @headers = {
            'Content-Type' => 'application/vnd.api+json; charset=utf-8'
          }
        end

        def status_code_to_symbol(code)
          text = Rack::Utils::HTTP_STATUS_CODES[code]
          raise Error::UnrecognizedStatusCode unless text

          text.underscore.tr(' ', '_').to_sym
        end

        def successful_status_code?(code)
          (code.to_i / 100) == 2
        end
      end
      # rubocop:enable Lint/UselessAccessModifier
    end
  end
end
