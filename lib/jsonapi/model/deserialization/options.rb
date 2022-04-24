module JSONAPI
  module Model
    module Deserialization
      # Tracks a context specification of option settings by keyword
      # @api private
      class Options
        class << self
          # List of supported option keywords
          attr_reader :supported_keywords

        private

          # @!macro [attach] supported_keyword
          #   @!attribute [rw] $1
          #     Assign or return value of \:$1 option
          #   @!method $1?
          #     @return [Boolean] true if \:$1 option has been assigned a value
          def supported_keyword(keyword)
            (@supported_keywords ||= []) << keyword

            attr_reader keyword

            define_method("#{keyword}=".to_sym) do |value|
              instance_variable_set("@#{keyword}".to_sym, normalize(value))
            end

            define_method("#{keyword}?".to_sym) do
              value = public_send(keyword)
              value && !value.empty?
            end
          end
        end

        # @!group For option keywords
        supported_keyword :only
        supported_keyword :except
        supported_keyword :polymorphic
        # @!endgroup

        # @param [Hash] initial_hash optional hash to set initial context for options
        def initialize(initial_hash = {})
          self.class.supported_keywords.each do |option|
            instance_variable_set("@#{option}".to_sym, [])
          end

          permit(initial_hash)&.keys&.each do |key|
            public_send("#{key}=".to_sym, initial_hash[key])
          end
        end

      private

        def normalize(value)
          Array(value).map(&:to_s)
        end

        def permit(candidate_options)
          return {} unless candidate_options.is_a?(Hash)

          candidate_options.select do |key, _|
            self.class.supported_keywords.include?(key)
          end
        end
      end
    end
  end
end
