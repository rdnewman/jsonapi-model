module JSONAPI
  module Model
    module Error
      # Error type for when response ID argument is malformed
      class InvalidIdArgument < Base
        def initialize
          super 'must provide id arguments as a UUID string ' \
                '("00000000-0000-0000-0000-000000000000")'
        end
      end
    end
  end
end
