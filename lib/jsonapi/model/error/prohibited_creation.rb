module JSONAPI
  module Model
    module Error
      # Error type to assert that #create(!) is prohibited once a resource ID is assigned
      class ProhibitedCreation < Base
        def initialize
          super '#create/#create! prohibited (e.g., after an id is assigned)'
        end
      end
    end
  end
end
