module MockApi
  module ResponseBody
    class Base
      class << self
      protected

        def as(content)
          content.to_json
        end

        def suite_type
          @suite_type ||= 'narrative'
        end
      end
    end
  end
end
