module JSONAPI
  module Model
    module Error
      # Error type for when a class derived from JSONAPI::Model::Base does not
      # specify how to serialize
      class NoSerializationTypeDefined < Base
        def initialize
          super 'must use "serialize_as" in class to define how to type for serializing in JSONAPI'
        end
      end
    end
  end
end
