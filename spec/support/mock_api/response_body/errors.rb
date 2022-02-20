module MockApi
  module ResponseBody
    class Errors < Base
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
  end
end
