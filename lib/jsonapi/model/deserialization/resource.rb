require_relative 'relationship'

module JSONAPI
  module Model
    module Deserialization
      # Deserializes individual resources present in JSONAPI hash
      # @api private
      class Resource
        class << self
          # Deserializes a resource
          #
          # @param [String] element name of resource to tie data to
          # @param [Options] options options for controlling deserialization
          # @return [Hash] result from deserializing response data
          def deserialize(element, options:)
            new(element).deserialize(options: options)
          end
        end

        # @param [String] element name of resource to tie data to
        def initialize(element)
          @element = element
        end

        # Deserializes a resource
        #
        # @param [Options] options options for controlling deserialization
        # @return [Hash] result from deserializing response data
        def deserialize(options:)
          @parsed = attributes
          @parsed['id'] = id if id

          # Remove unwanted items
          reduce!(options)

          # Append any (remaining) relationships
          relationships.map do |name, data|
            @parsed.merge!(
              Relationship.deserialize(name: name, data: data, options: options)
            )
          end

          parsed
        end

      private

        attr_reader :element, :parsed

        def attributes
          @attributes ||= element['attributes'] || {}
        end

        def id
          @id ||= element['id']
        end

        def relationships
          @relationships ||= element['relationships'] || {}
        end

        def reduce!(options)
          if options.only?
            [parsed, relationships].map { |hsh| hsh.slice!(*options.only) }
          elsif options.except?
            [parsed, relationships].map { |hsh| hsh.except!(*options.except) }
          end
        end
      end
    end
  end
end
