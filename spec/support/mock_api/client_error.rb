module MockApi
  class ClientError < BaseResponse
    class << self
      def not_found
        respond_with(404)
      end

      def bad_key
        respond_with(422, ResponseBody::Errors.bad_key)
      end

      def bad_type
        respond_with(422, ResponseBody::Errors.bad_type)
      end

      def descriptions_are_blank
        respond_with(422, ResponseBody::Errors.descriptions_are_blank)
      end

      def all_attributes_are_blank
        respond_with(422, ResponseBody::Errors.all_attributes_are_blank)
      end
    end
  end
end
