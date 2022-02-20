module JSONAPI
  module Model
    module Error
      # Error type for when a class derived from JSONAPI::Model::Base does not define attributes
      class NoAttributesDefined < Base
        def initialize
          super 'must define attributes (via attr_accessor) in class to exchange'
        end
      end
    end
  end
end
