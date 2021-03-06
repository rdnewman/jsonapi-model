module MockApi
  module ResponseBody
    class Data < Base
      class << self
        def single_resource(uuid, attributes)
          as({ data: { id: uuid, type: MockApi.suite_name, attributes: attributes } })
        end

        def empty_collection
          as({ data: [] })
        end
      end
    end
  end
end
