module JSONAPI
  module Model
    module Error
      # Error type for when a class derived from JSONAPI::Model::Base does not specify use_host
      class NoHostDefined < Base
        def initialize
          super 'must use "use_host" in class to define a host URL to connect to'
        end
      end
    end
  end
end
