require_relative 'deserialization'

module JSONAPI
  module Model
    # For JSONAPI parsing of response from remote endpoint
    class Jsonapi
      class << self
        # Parses received content from a JSONAPI response
        #
        # @param [String] jsonapi_content_string
        # @param [Hash] options for controlling deserialization
        # @return [Hash] parsed data
        def parse(jsonapi_content_string, options = {})
          new(jsonapi_content_string, options).parse
        end
      end

      # @param [String] jsonapi_content_string received content from a JSONAPI response
      # @param [Hash] options for controlling deserialization
      def initialize(jsonapi_content_string, options = {})
        raise EmptyResponseReceived unless jsonapi_content_string.present?

        @raw_content = JSON.parse(jsonapi_content_string)&.with_indifferent_access
        @options = options

        parse
      rescue StandardError => e
        raise DeserializeFailure, e.message
      end

      # Parses received content from a JSONAPI response
      #
      # @return [Hash] parsed data
      def parse
        @parse ||= if @raw_content[:data]
                     DataResponseStrategy.parse(@raw_content, @options)
                   elsif @raw_content[:errors]
                     ErrorResponseStrategy.parse(@raw_content, @options)
                   else
                     raise UnrecognizedResponse
                   end
      end

      # Base strategy for interpreting endpoint response
      # @api private
      class ResponseStrategy
        class << self
          # Parses received content from a successful JSONAPI response
          #
          # @param [String] jsonapi_content_string received content from a JSONAPI response
          # @param [Hash] options for controlling deserialization
          # @return [Hash] parsed data
          def parse(jsonapi_content_string, options = {})
            new.parse(jsonapi_content_string, options)
          end
        end

        def parse(_content, _options = {})
          raise NoMethodError, 'must implement in subclass'
        end
      end

      # Strategy for handling successful data filled responses
      # @api private
      class DataResponseStrategy < ResponseStrategy
        # Parses received content from a successful JSONAPI response
        #
        # @param [String] content content to parse, containing data
        # @param [Hash] options for controlling deserialization
        # @return [Hash] parsed data
        def parse(content, options = {})
          result = JSONAPI::Model::Deserialization.deserialize(
            content,
            only: options[:only],
            except: options[:except],
            polymorphic: options[:polymorphic]
          ) || {}

          return result.with_indifferent_access unless result.is_a?(Array)

          data_collection(result, content&.fetch('meta', {}))
        end

      private

        def data_collection(collection, metadata = {})
          expected_count = metadata&.fetch('count', nil)
          raise DeserializeCountMismatch if expected_count && (collection.count != expected_count)

          collection.map(&:with_indifferent_access)
        end
      end

      # Strategy for handling error responses
      # @api private
      class ErrorResponseStrategy < ResponseStrategy
        # Parses received content from a failed JSONAPI response
        #
        # @param [String] content content to parse, containing errors
        # @param [Hash] _options for controlling deserialization [not used]
        # @return [Hash] parsed data
        def parse(content, _options = {})
          errors = content['errors']
          return {} unless errors

          # TODO: far too simplistic!
          {
            title: errors.first['title'],
            source: errors.first['source']['pointer'],
            detail: errors.first['detail']
          }
        end
      end

      # Error type for when response is empty
      class EmptyResponseReceived < StandardError; end

      # Error type for when response cannot be deserialized
      class DeserializeFailure < StandardError; end

      # Error type for when response is an array but does not match count in metadata
      class DeserializeCountMismatch < StandardError
        def initialize
          super(
            'received data contains an array, but count of objects deserialized ' \
            'does not match value in { meta: { count: } }'
          )
        end
      end

      # Error type for when response strategy is indeterminate
      class UnrecognizedResponse < StandardError; end
    end
  end
end
