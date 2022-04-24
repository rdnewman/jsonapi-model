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

    context 'when "serialize_as' do
      let(:attributes) do
        {
          name: Faker::Lorem.words.join(' '),
          short_description: Faker::Lorem.words.join(' '),
          description: Faker::Lorem.words.join(' '),
          submission_details: Faker::Lorem.words.join(' ')
        }
      end

      describe 'is missing' do
        let(:klass) do
          Class.new(described_class) do
            use_host 'http://127.0.0.1:3000'
            use_endpoint '/v1/narratives/'
            # serialize_as :narrative

            attr_accessor :name, :short_description, :description, :submission_details
          end
        end

        it '.create fails' do
          expect { klass.create(attributes) }
            .to raise_error JSONAPI::Model::Error::NoSerializationTypeDefined
        end
      end

      describe 'is invalid' do
        let(:klass) do
          Class.new(described_class) do
            use_host 'http://127.0.0.1:3000'
            use_endpoint '/v1/narratives/'
            serialize_as 5 # invalid serialize_as type -- should be a symbol

            attr_accessor :name, :short_description, :description, :submission_details
          end
        end

        it '.create fails' do
          expect { klass.create(attributes) }
            .to raise_error JSONAPI::Model::Error::InvalidSerializationType
        end
      end
    end

    context 'when missing attributes' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'http://127.0.0.1:3000'
          use_endpoint '/v1/narratives/'
          serialize_as :narrative

          # attr_accessor :name, :short_description, :description, :submission_details
        end
      end

      let(:arbitrary_id) { Faker::Internet.uuid }
      let(:attributes) do
        {
          name: Faker::Lorem.words.join(' '),
          short_description: Faker::Lorem.words.join(' '),
          description: Faker::Lorem.words.join(' '),
          submission_details: Faker::Lorem.words.join(' ')
        }
      end

      before do
        allow(klass.connection)
          .to receive(:get)
          .and_return(MockApi::Successful.resource(arbitrary_id, attributes))

        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(arbitrary_id, attributes))
      end

      it 'raises ActiveModel::UnknownAttributeError when finding' do
        expect { klass.find(arbitrary_id) }
          .to raise_error ActiveModel::UnknownAttributeError
      end

      it 'raises ActiveModel::UnknownAttributeError when initializing an object with data' do
        expect { klass.new(attributes) }
          .to raise_error ActiveModel::UnknownAttributeError
      end

      it 'raises NoAttributesDefined when saving' do
        object = klass.new

        expect { object.save! }
          .to raise_error JSONAPI::Model::Error::NoAttributesDefined
      end
    end
  end
end
