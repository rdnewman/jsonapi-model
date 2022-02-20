module MockApi
  class Successful < BaseResponse
    class << self
      def resource(uuid, attributes)
        respond_with(200, ResponseBody::Data.single_resource(uuid, attributes))
      end

      def created_resource(uuid, attributes)
        respond_with(201, ResponseBody::Data.single_resource(uuid, attributes))
      end

      def empty_collection
        respond_with(200, ResponseBody::Data.empty_collection)
      end
    end
  end
end
