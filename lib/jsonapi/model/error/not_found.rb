module JSONAPI
  module Model
    module Error
      # Error type for when a resource ID is not recognized by the remote endpoint
      class NotFound < Base
        def initialize(id = nil)
          super(id ? "id #{id} not found" : 'not found -- id is nil')
        end
      end
    end
  end
end
