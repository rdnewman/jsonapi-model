module JSONAPI
  module Model
    module Error
      # Error type for when a class derived from JSONAPI::Model::Base does not specify use_endpoint
      class NoEndpointDefined < Base
        def initialize
          super 'must use "use_endpoint" in class to define an ' \
                'endpoint path for the URL to connect to'
        end
      end
    end
  end
end
