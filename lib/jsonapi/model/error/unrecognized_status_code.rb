module JSONAPI
  module Model
    module Error
      # Error type for when a response status code from the remote endpoint is unrecognized
      class UnrecognizedStatusCode < Base
        def initialize
          super 'unrecognized HTTP_STATUS_CODE value'
        end
      end
    end
  end
end
