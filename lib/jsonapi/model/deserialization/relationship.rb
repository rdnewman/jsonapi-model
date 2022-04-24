module JSONAPI
  module Model
    module Deserialization
      # Resolves deserialization for relationships in JSONAPI elements
      # @api private
      class Relationship
        class << self
          # Deserializes a relationship
          #
          # @param [String] name name of related resource to tie data to
          # @param [Hash] data data from response containing :data top level key
          # @param [Options] options options for controlling deserialization
          # @return [Hash] result from deserializing response data
          def deserialize(name:, data:, options:)
            new(name: name, data: data).deserialize(options: options)
          end
        end

        # @param [String] name name of related resource to tie data to
        # @param [Hash] data data from response containing :data top level key
        def initialize(name:, data:)
          @given_name = name
          @given_data = data
        end

        # Deserializes a relationship
        #
        # @param [Options] options options for controlling deserialization
        # @return [Hash] result from deserializing response data
        def deserialize(options:)
          result = { id_key => ids }

          return result if array?
          return result unless options.polymorphic?
          return result unless (options.polymorphic || []).include?(name)

          result[type_key] = type

          result
        end

      private

        attr_reader :given_name, :given_data, :polymorphic

        def name
          @name ||= ActiveSupport::Inflector.singularize(given_name)
        end

        def data
          @data ||= (given_data || {})['data'] || {}
        end

        def array?
          @array ||= data.is_a?(Array)
        end

        def id_key
          array? ? "#{name}_ids" : "#{name}_id"
        end

        def ids
          if array?
            data.map { |item| item['id'] }.compact
          else
            data['id']
          end
        end

        def type_key
          "#{name}_type"
        end

        def type
          ActiveSupport::Inflector.classify(data['type'].to_s)
        end
      end
    end
  end
end
