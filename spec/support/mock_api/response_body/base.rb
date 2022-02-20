module MockApi
  module ResponseBody
    class Base
      class << self
      protected

        def as(content)
          content.to_json
        end
      end
    end
  end
end
