module JSONAPI
  module Model
    module Error
      # Error type for when a core validation is not met in the response
      class ValidationsFailed < Base
        def initialize(validation_errors = [])
          if validation_errors && !validation_errors.empty?
            super 'one or more validations failed: ' \
                  "#{validation_errors.full_messages.join('; ')}"
          else
            super 'one or more validations failed'
          end
        end
      end
    end
  end
end
