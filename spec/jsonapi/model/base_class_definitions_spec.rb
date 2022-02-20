RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'class methods for definition' do
    context 'when missing "use_host"' do
      let(:klass) do
        Class.new(described_class) do
          # use_host 'http://127.0.0.1:3000'
          use_endpoint '/v1/narratives/'
          serialize_as :narrative
        end
      end

      it '.connection fails' do
        expect { klass.connection }.to raise_error JSONAPI::Model::Error::NoHostDefined
      end
    end

    context 'when "use_host" specifies an invalid host' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'malformed url'
          use_endpoint '/v1/narratives/'
          serialize_as :narrative
        end
      end

      it '.connection fails' do
        expect { klass.connection }.to raise_error JSONAPI::Model::Error::InvalidHost
      end
    end

    context 'when missing "use_endpoint"' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'http://127.0.0.1:3000'
          # use_endpoint '/v1/narratives/'
          serialize_as :narrative
        end
      end

      it '.all fails' do
        expect { klass.all }.to raise_error JSONAPI::Model::Error::NoEndpointDefined
      end
    end

    context 'when missing "serialize_as"' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'http://127.0.0.1:3000'
          use_endpoint '/v1/narratives/'
          # serialize_as :narrative

          attr_accessor :name, :short_description, :description, :submission_details
        end
      end

      let(:attributes) do
        {
          name: Faker::Lorem.words.join(' '),
          short_description: Faker::Lorem.words.join(' '),
          description: Faker::Lorem.words.join(' '),
          submission_details: Faker::Lorem.words.join(' ')
        }
      end

      it '.create fails' do
        expect { klass.create(attributes) }
          .to raise_error JSONAPI::Model::Error::NoSerializationTypeDefined
      end
    end
  end
end
