module JSONAPI
  module Model
    module Error
      # Base error type for all JSONAPI::Model custom error types
      class Base < StandardError
        def initialize(msg = nil)
          super "[JSONAPI::Model] #{msg || self.class.name.demodulize}"
        end
      end
    end
  end
end
