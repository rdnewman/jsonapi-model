module MockApi
  class ServerError < BaseResponse
    class << self
      def server_error
        respond_with(500)
      end
    end
  end
end
