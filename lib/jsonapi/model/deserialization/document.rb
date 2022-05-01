require_relative 'options'
require_relative 'resource'

module JSONAPI
  module Model
    module Deserialization
      # Deserializes a JSONAPI-format document based on [ActiveRecord::Base]
      # @api private
      class Document
        class << self
          # Returns a transformed hash based on [ActiveRecord::Base] specs
          #
          # @param [Hash|ActionController::Parameters] content document in JSONAPI format
          # @param [Symbol|Array<Symbol>] only whitelisted field(s)
          # @param [Symbol|Array<Symbol>] except blacklisted field(s)
          # @param [Symbol|Array<Symbol>] polymorphic polymorphic field(s)
          #
          # @return [Hash]
          def deserialize(content, only: [], except: [], polymorphic: [])
            new(content).deserialize(only: only, except: except, polymorphic: polymorphic)
          end
        end

        # @param content [Hash, ActionController::Parameters] document in JSONAPI format
        def initialize(content)
          @given_document = content
        end

        # Returns a transformed dictionary based on [ActiveRecord::Base] specs
        #
        # @param kwargs keyword parameters to supply options
        # @option kwargs [Symbol|Array<Symbol>] only whitelisted field(s)
        # @option kwargs [Symbol|Array<Symbol>] except blacklisted field(s)
        # @option kwargs [Symbol|Array<Symbol>] polymorphic polymorphic field(s)
        #
        # @return [Hash]
        def deserialize(**kwargs)
          options = Options.new(kwargs)
          single_resource(options) || multiple_resources(options)
        end

      private

        attr_reader :given_document

        def document
          @document ||= (controller_parameters || mundane_hash || {})
        end

        def single_resource(options)
          return if document.is_a?(Array)

          Resource.deserialize(document, options: options)
        end

        def multiple_resources(options)
          return unless document.is_a?(Array)

          document.map { |datum| Resource.deserialize(datum, options: options) }
        end

        def controller_parameters
          return nil unless given_document.respond_to?(:permit!)

          data = given_document.dup.require(:data)

          permitted = data.is_a?(Array) ? data.map(&:permit!) : data.permit!
          permitted.as_json
        end

        def mundane_hash
          return nil unless given_document.is_a?(Hash)

          (given_document.as_json['data'] || {}).deep_dup
        end
      end
    end
  end
end
