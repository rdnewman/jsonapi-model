module JSONAPI
  module Model
    # The logic for the Deserialization model was first inspired by Stas Sușcov's
    # jsonapi.rb gem (source: https://github.com/stas/jsonapi.rb, as of April 23, 2022).
    # It has been heavily adapted and refactored for this gem.
    # See the relevant part of Mr. Sușcov's original code at
    # https://raw.githubusercontent.com/stas/jsonapi.rb/master/lib/jsonapi/deserialization.rb

    # Helpers to transform a JSON API document, containing a single data object,
    # into a hash that can be used to create an [ActiveRecord::Base] instance.
    module Deserialization
      # Returns a transformed dictionary based on [ActiveRecord::Base] specs
      #
      # @param document [Hash|ActionController::Parameters] document in JSONAPI format
      # @param only [Symbol|Array<Symbol>] whitelisted field(s)
      # @param except [Symbol|Array<Symbol>] blacklisted field(s)
      # @param polymorphic [Symbol|Array<Symbol>] polymorphic field(s)
      # @return [Hash]
      def self.deserialize(document, only: [], except: [], polymorphic: [])
        Document.deserialize(
          document,
          only: only,
          except: except,
          polymorphic: polymorphic
        )
      end
    end
  end
end
