RSpec.shared_context 'for base instance' do
  let(:validating_klass) do
    Class.new(described_class) do
      use_host 'http://127.0.0.1:3000'
      use_endpoint '/v1/narratives/'
      serialize_as :narrative

      attr_accessor :name, :short_description, :description, :submission_details

      validates :name, presence: true
      validates :short_description, presence: true
      validates :description, presence: true
      validates :submission_details, presence: true

      # this is only for testing with validations when anonymous classes are involved;
      # defining this method is not typically needed in regular use
      def self.model_name
        ActiveModel::Name.new(
          self,
          nil,
          "#{File.basename(__FILE__, '.rb')}_validating_klass"
        )
      end
    end
  end

  let(:unvalidating_klass) do
    Class.new(described_class) do
      use_host 'http://127.0.0.1:3000'
      use_endpoint '/v1/narratives/'
      serialize_as :narrative

      attr_accessor :name, :short_description, :description, :submission_details
    end
  end

  let(:unconforming_klass) do
    Class.new(described_class) do
      use_host 'http://127.0.0.1:3000'
      use_endpoint '/v1/narratives/'
      serialize_as :narrative

      attr_accessor :bad_key, :name, :short_description, :description, :submission_details
    end
  end

  let(:valid_uuid_format) { /\h{8}-\h{4}-4\h{3}-[89AB]\h{3}-\h{12}/i } # version 4, non-null

  let(:arbitrary_id) { Faker::Internet.uuid }

  let(:valid_attributes) do
    {
      name: Faker::Lorem.words.join(' '),
      short_description: Faker::Lorem.words.join(' '),
      description: Faker::Lorem.words.join(' '),
      submission_details: Faker::Lorem.words.join(' ')
    }
  end

  let(:changed_attributes) do
    {
      name: Faker::Lorem.words.join(' '),
      short_description: Faker::Lorem.words.join(' '),
      description: Faker::Lorem.words.join(' '),
      submission_details: Faker::Lorem.words.join(' ')
    }
  end

  let(:missing_attributes) do
    {
      name: Faker::Lorem.words.join(' '),
      submission_details: Faker::Lorem.words.join(' ')
    }
  end

  let(:wrong_attributes) do
    {
      name: Faker::Lorem.words.join(' '),
      bad_key: Faker::Lorem.words.join(' ')
    }
  end

  let(:original_object) { object.clone }
end
