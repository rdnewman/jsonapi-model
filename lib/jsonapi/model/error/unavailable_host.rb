module JSONAPI
  module Model
    module Error
      # Error type for when the remote host for the endpoint is not available
      class UnavailableHost < Base
        def initialize(host)
          super "host at #{host} refused connection -- verify it is running"
        end
      end
    end
  end
end
