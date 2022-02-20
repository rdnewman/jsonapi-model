class MockResponse
  class << self
  protected

    def respond_with(status, body = nil)
      Excon::Response.new(status: status, body: body)
    end
  end
end

class MockSuccessful < MockResponse
  class << self
    def resource(uuid, attributes)
      respond_with(200, MockData.single_resource(uuid, attributes))
    end

    def created_resource(uuid, attributes)
      respond_with(201, MockData.single_resource(uuid, attributes))
    end

    def empty_collection
      respond_with(200, MockData.empty_collection)
    end
  end
end

class MockClientError < MockResponse
  class << self
    def not_found
      respond_with(404)
    end

    def bad_key
      respond_with(422, MockErrors.bad_key)
    end

    def bad_type
      respond_with(422, MockErrors.bad_type)
    end

    def descriptions_are_blank
      respond_with(422, MockErrors.descriptions_are_blank)
    end

    def all_attributes_are_blank
      respond_with(422, MockErrors.all_attributes_are_blank)
    end
  end
end

class MockBody
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

class MockData < MockBody
  class << self
    def single_resource(uuid, attributes)
      as({ data: { id: uuid, type: suite_type, attributes: attributes } })
    end

    def empty_collection
      as({ data: [] })
    end
  end
end

class MockErrors < MockBody
  class << self
    def all_attributes_are_blank
      as(
        {
          errors: [
            {
              title: 'blank ',
              source: { pointer: '/data/attributes/name' },
              detail: "Name can't be blank"
            },
            {
              title: 'blank',
              source: { pointer: '/data/attributes/description' },
              detail: "Description can't be blank"
            },
            {
              title: 'blank',
              source: { pointer: '/data/attributes/short_description' },
              detail: "Short description can't be blank"
            },
            {
              title: 'blank',
              source: { pointer: '/data/attributes/submission_details' },
              detail: "Submission details can't be blank"
            }
          ]
        }
      )
    end

    def descriptions_are_blank
      as(
        {
          errors: [
            {
              title: 'blank',
              source: { pointer: '/data/attributes/description' },
              detail: "Description can't be blank"
            },
            {
              title: 'blank',
              source: { pointer: '/data/attributes/short_description' },
              detail: "Short description can't be blank"
            }
          ]
        }
      )
    end

    def bad_key
      as(
        {
          errors: [
            {
              title: 'unpermitted',
              source: { pointer: '/data/attributes/bad_key' },
              detail: 'parameter key not allowed: :bad_key'
            }
          ]
        }
      )
    end

    def bad_type
      as(
        {
          errors: [
            {
              title: 'blank',
              source: { pointer: "/data/attributes/#{suite_type}" },
              detail: "param is missing or the value is empty: #{suite_type}\n" \
                      'Did you mean?  bad_type'
            }
          ]
        }
      )
    end
  end
end
