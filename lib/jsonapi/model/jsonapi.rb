module JSONAPI
  # begin
  #   require 'active_support/inflector'
  # rescue LoadError
  #   warn(
  #     'Trying to load `dry-inflector` as an ' \
  #     'alternative to `active_support/inflector`...'
  #   )
  #   require 'dry/inflector'
  # end

  # Helpers to transform a JSON API document, containing a single data object,
  # into a hash that can be used to create an [ActiveRecord::Base] instance.
  #
  # Initial version from the `active_model_serializers` support for JSONAPI.
  module Deserialization
  private

    # Helper method to pick an available inflector implementation
    #
    # @return [Object]
    def jsonapi_inflector
      ActiveSupport::Inflector
    # rescue
    #   Dry::Inflector.new
    end

    # Returns a transformed dictionary following [ActiveRecord::Base] specs
    #
    # @param [Hash|ActionController::Parameters] document
    # @param [Hash] options
    #   only: Array of symbols of whitelisted fields.
    #   except: Array of symbols of blacklisted fields.
    #   polymorphic: Array of symbols of polymorphic fields.
    # @return [Hash]
    def jsonapi_deserialize(document, options = {})
      if document.respond_to?(:permit!)
        # Handle Rails params...
        primary_data = document.dup.require(:data).permit!.as_json
      elsif document.is_a?(Hash)
        primary_data = (document.as_json['data'] || {}).deep_dup
      else
        return {}
      end

      # Transform keys and any option values.
      options = options.as_json
      ['only', 'except', 'polymorphic'].each do |opt_name|
        opt_value = options[opt_name]
        options[opt_name] = Array(opt_value).map(&:to_s) if opt_value
      end

      # relationships = primary_data['relationships'] || {}
      # parsed = primary_data['attributes'] || {}
      # parsed['id'] = primary_data['id'] if primary_data['id']

      if primary_data.is_a?(Array)
        primary_data.map do |datum|
          jsonapi_deserialize_data_element(datum, options)
        end
      else
        jsonapi_deserialize_data_element(primary_data, options)
      end
    end

    # Returns a transformed dictionary following [ActiveRecord::Base] specs for
    # a single data element
    #
    # @param [Hash] data_element
    # @param [Hash] options
    #   only: Array of symbols of whitelisted fields.
    #   except: Array of symbols of blacklisted fields.
    #   polymorphic: Array of symbols of polymorphic fields.
    # @return [Hash]
    def jsonapi_deserialize_data_element(data_element, options = {})
      relationships = data_element['relationships'] || {}
      parsed = data_element['attributes'] || {}
      parsed['id'] = data_element['id'] if data_element['id']

      # Remove unwanted items from a dictionary.
      if options['only']
        [parsed, relationships].map { |hsh| hsh.slice!(*options['only']) }
      elsif options['except']
        [parsed, relationships].map { |hsh| hsh.except!(*options['except']) }
      end

      relationships.map do |assoc_name, assoc_data|
        assoc_data = (assoc_data || {})['data'] || {}
        rel_name = jsonapi_inflector.singularize(assoc_name)

        if assoc_data.is_a?(Array)
          parsed["#{rel_name}_ids"] = assoc_data.map { |ri| ri['id'] }.compact
          next
        end

        parsed["#{rel_name}_id"] = assoc_data['id']

        if (options['polymorphic'] || []).include?(assoc_name)
          rel_type = jsonapi_inflector.classify(assoc_data['type'].to_s)
          parsed["#{rel_name}_type"] = rel_type
        end
      end

      parsed
    end
  end

  module Model
    # For JSONAPI parsing of response from remote endpoint
    class Jsonapi
      class << self
        def parse(jsonapi_content_string, options = {})
          new(jsonapi_content_string, options).parse
        end
      end

      def initialize(jsonapi_content_string, options = {})
        raise EmptyResponseReceived unless jsonapi_content_string.present?

        @raw_content = JSON.parse(jsonapi_content_string)&.with_indifferent_access
        @options = options

        parse
      rescue StandardError => e
        raise DeserializeFailure, e.message
      end

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
      class ResponseStrategy
        class << self
          def parse(jsonapi_content_string, options = {})
            new.parse(jsonapi_content_string, options)
          end
        end

        def parse(_content, _options = {})
          raise NoMethodError, 'must implement in subclass'
        end
      end

      # Strategy for handling successful data filled responses
      class DataResponseStrategy < ResponseStrategy
        include JSONAPI::Deserialization

        def parse(content, options = {})
          result = jsonapi_deserialize(content, options) || {}
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
      class ErrorResponseStrategy < ResponseStrategy
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
