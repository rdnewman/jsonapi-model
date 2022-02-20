module MockApi
  module ResponseBody
    class Errors < Base
      class << self
        def all_attributes_are_blank
          errors = [:name, :description, :short_description, :submission_details].map do |item|
            {
              title: 'blank ',
              source: { pointer: "/data/attributes/#{item}" },
              detail: "#{item.to_s.humanize} can't be blank"
            }
          end

          as({ errors: errors })
        end

        def descriptions_are_blank
          errors = [:description, :short_description].map do |item|
            {
              title: 'blank ',
              source: { pointer: "/data/attributes/#{item}" },
              detail: "#{item.to_s.humanize} can't be blank"
            }
          end

          as({ errors: errors })
        end

        def bad_key
          as({ errors: [
            {
              title: 'unpermitted',
              source: { pointer: '/data/attributes/bad_key' },
              detail: 'parameter key not allowed: :bad_key'
            }
          ] })
        end

        def bad_type
          as({ errors: [
            {
              title: 'blank',
              source: { pointer: "/data/attributes/#{MockApi.suite_name}" },
              detail: "param is missing or the value is empty: #{MockApi.suite_name}\n" \
                      'Did you mean?  bad_type'
            }
          ] })
        end
      end
    end
  end
end
