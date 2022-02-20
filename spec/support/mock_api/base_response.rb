module MockApi
  class BaseResponse
    class << self
    protected

      def respond_with(status, body = nil)
        Excon::Response.new(status: status, body: body)
      end
    end
  end
end
