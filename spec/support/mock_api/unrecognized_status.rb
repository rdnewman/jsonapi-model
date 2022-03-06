module MockApi
  class UnrecognizedStatus < BaseResponse
    class << self
      def weird_status_code_of(status_code:)
        respond_with(status_code)
      end
    end
  end
end
