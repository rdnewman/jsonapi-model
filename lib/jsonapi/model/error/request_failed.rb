module JSONAPI
  module Model
    module Error
      # Error type for any remote endpoing request failure
      class RequestFailed < Base
        attr_reader :response, :status_code

        # @param [Object] object object raising this exception
        # @param [Excon::Response] response response from endpoint
        def initialize(object, response)
          @raising_object = object
          @response = response
          @status_code = response.status

          super(construct_message)
        end

        # Determines a specific description of error based on received response
        #
        # @return [String] specific description
        def description
          return @description if @description

          body = response.body
          @description = if body.present?
                           JSONAPI::Model::Jsonapi.parse(body)[:detail]
                         else
                           @description = response.reason_phrase
                         end
        end

        # Determines mnemonic symbol based on HTTP response status code
        #
        # @return [Symbol] symbol from response status code
        def status_symbol
          @status_symbol ||= @raising_object.__send__(:status_code_to_symbol, status_code)
        rescue UnrecognizedStatusCode
          :unrecognized_status_code
        end

      private

        def construct_message
          msg = 'JSONAPI::Model request failed - ' \
                "#{status_symbol} (#{status_code})"
          msg += ": #{description}" if description
          msg
        end
      end
    end
  end
end
