RSpec.describe JSONAPI::Model::Base, type: :model do
  let(:klass) do
    Class.new(described_class) do
      use_host 'http://127.0.0.1:3000'
      use_endpoint '/v1/narratives/'
      serialize_as :narrative

      attr_accessor :name, :short_description, :description, :submission_details
    end
  end
  let(:valid_uuid_format) { /\h{8}-\h{4}-4\h{3}-[89AB]\h{3}-\h{12}/i } # version 4, non-null

  let(:absent_id) { Faker::Internet.uuid }

  let(:attributes) { build_attributes }

  def build_attributes
    {
      name: Faker::Lorem.words.join(' '),
      short_description: Faker::Lorem.words.join(' '),
      description: Faker::Lorem.words.join(' '),
      submission_details: Faker::Lorem.words.join(' ')
    }
  end

  context 'for finding' do
    let(:created_id) { Faker::Internet.uuid }

    context 'for an existing object' do
      let(:existing_id) { klass.create!(attributes) }

      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(created_id, attributes))

        allow(klass.connection)
          .to receive(:get)
          .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
          .and_return(MockApi::Successful.resource(created_id, attributes))

        existing_id
      end

      it '.find succeeds' do
        expect(klass.find(existing_id)).to be_a klass
      end

      it '[] succeeds' do
        expect(klass[existing_id]).to be_a klass
      end
    end

    context 'when id cannot be found' do
      before do
        allow(klass.connection)
          .to receive(:get)
          .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
          .and_return(MockApi::ClientError.not_found)
      end

      it '.find raises NotFound error' do
        expect { klass.find(absent_id) }.to raise_error JSONAPI::Model::Error::NotFound
      end

      it '[] raises NotFound error' do
        expect { klass[absent_id] }.to raise_error JSONAPI::Model::Error::NotFound
      end
    end

    describe '.find' do
      it 'raises InvalidIdArgument when no id given' do
        expect { klass.find }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end

      it 'raises InvalidIdArgument when id given is nil' do
        expect { klass.find(nil) }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end

      it 'raises InvalidIdArgument when id given is invalid type' do
        expect { klass.find(5) }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end
    end

    describe '[]' do
      it 'raises InvalidIdArgument when no id given' do
        expect { klass[] }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end

      it 'raises InvalidIdArgument when id given is nil' do
        expect { klass[nil] }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end

      it 'raises InvalidIdArgument when id given is invalid type' do
        expect { klass[5] }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end
    end
  end

  describe 'for creation' do
    describe '.create' do
      let(:created_id) { Faker::Internet.uuid }

      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(created_id, attributes))
      end

      it 'returns an id of the created record' do
        expect(klass.create(attributes)).to match valid_uuid_format
      end

      it 'allows the record to be retrieved by the returned id' do
        id = klass.create(attributes)

        allow(klass.connection)
          .to receive(:get)
          .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
          .and_return(MockApi::Successful.resource(created_id, attributes))

        expect(klass.find(id)).to be_a klass
      end

      it 'replaces any id set before the creation' do
        object = klass.new(attributes)
        object.id = absent_id
        raise 'did not prepare test as expected' unless object.id == absent_id

        expect(klass.create(attributes)).not_to eq absent_id
      end

      it 'raises NotCreated when no data is passed for attributes' do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::ClientError.all_attributes_are_blank)

        expect { klass.create }.to raise_error JSONAPI::Model::Error::NotCreated
      end

      it 'raises UnknownAttributeError when an unknown attribute is given' do
        expect { klass.create(huga: 'hooga') }.to raise_error ActiveModel::UnknownAttributeError
      end
    end

    describe '.create!' do
      let(:created_id) { Faker::Internet.uuid }

      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(created_id, attributes))
      end

      it 'returns an id of the created record' do
        expect(klass.create!(attributes)).to match valid_uuid_format
      end

      it 'allows the record to be retrieved by the returned id' do
        id = klass.create!(attributes)

        allow(klass.connection)
          .to receive(:get)
          .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
          .and_return(MockApi::Successful.resource(created_id, attributes))

        expect(klass.find(id)).to be_a klass
      end

      it 'replaces any id set before the creation' do
        object = klass.new(attributes)
        object.id = absent_id
        raise 'did not prepare test as expected' unless object.id == absent_id

        expect(klass.create!(attributes)).not_to eq absent_id
      end

      it 'raises RequestFailed when no data is passed for attributes' do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::ClientError.all_attributes_are_blank)

        expect { klass.create! }
          .to raise_error JSONAPI::Model::Error::RequestFailed, /unprocessable_entity/
      end

      it 'raises UnknownAttributeError when an unknown attribute is given' do
        expect { klass.create!(huga: 'hooga') }.to raise_error ActiveModel::UnknownAttributeError
      end
    end
  end

  context 'upon collections' do
    let(:raw_instance_data_set) do
      Array.new(3) do
        {
          id: Faker::Internet.uuid,
          attributes: build_attributes
        }
      end
    end

    let(:instances) do
      raw_instance_data_set.map do |raw_instance|
        klass.create!(raw_instance[:attributes])
      end
    end

    let(:ids) do
      raw_instance_data_set.map { |raw_instance| raw_instance[:id] }
    end

    let(:mocked_individual_create_responses) do
      raw_instance_data_set.map do |raw_instance|
        MockApi::Successful.created_resource(raw_instance[:id], raw_instance[:attributes])
      end
    end

    let(:mocked_individual_get_responses) do
      raw_instance_data_set.map do |raw_instance|
        MockApi::Successful.resource(raw_instance[:id], raw_instance[:attributes])
      end
    end

    let(:mocked_individual_delete_responses) do
      raw_instance_data_set.map do |raw_instance|
        MockApi::Successful.resource(raw_instance[:id], raw_instance[:attributes])
      end
    end

    let(:collection_json_response) do
      {
        data: raw_instance_data_set.map do |raw_instance|
          {
            id: raw_instance[:id],
            type: 'narrative',
            attributes: raw_instance[:attributes]
          }
        end
      }.to_json
    end

    let(:mocked_collection_get_responses) do
      Excon::Response.new(
        status: 200,
        body: collection_json_response
      )
    end

    before do
      allow(klass.connection)
        .to receive(:post)
        .and_return(*mocked_individual_create_responses)

      allow(klass.connection)
        .to receive(:get)
        .with(path: '/v1/narratives/')
        .and_return(mocked_collection_get_responses)

      allow(klass.connection)
        .to receive(:get)
        .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
        .and_return(*mocked_individual_get_responses)

      allow(klass.connection)
        .to receive(:delete)
        .and_return(*mocked_individual_delete_responses)
    end

    describe '.all' do
      subject(:all) { klass.all }

      it 'returns an empty array when no records exist' do
        allow(klass.connection)
          .to receive(:get)
          .with(path: '/v1/narratives/')
          .and_return(MockApi::Successful.empty_collection)

        expect(all).to be_empty
      end

      it 'returns array with all the records that exist' do
        instances # prepare records

        expect(all.count).to eq instances.count
      end

      it 'returns array where any element matches its individual counterpart' do
        some_element = rand(0..(instances.count - 1))

        allow(klass.connection)
          .to receive(:get)
          .with(path: Regexp.new("/v1/narratives#{/\/+/}#{valid_uuid_format}"))
          .and_return(mocked_individual_get_responses[some_element])

        expect(all[some_element]).to eq klass.find(instances[some_element])
      end
    end

    describe '.destroy_all' do
      before { instances }

      it 'returns an Array' do
        expect(klass.destroy_all).to be_an Array
      end

      it 'returns an Array that is not empty' do
        expect(klass.destroy_all).not_to be_empty
      end

      it 'returns collection of records destroyed that matches the original records' do
        skip "check that this actually works and that original records isn't just empty"

        original_records = ids.map { |id| klass.find(id) }

        destroyed_records = klass.destroy_all
        expect(destroyed_records).to eq original_records
      end

      it 'results in no records remaining' do
        klass.destroy_all

        allow(klass.connection)
          .to receive(:get)
          .with(path: '/v1/narratives/')
          .and_return(MockApi::Successful.empty_collection)
        expect(klass.all).to be_empty
      end

      it 'returns collection of records that are marked as destroyed' do
        destroyed_records = klass.destroy_all
        expect(destroyed_records.all?(&:destroyed?)).to be true
      end

      it 'returns collection of records that are marked as frozen' do
        destroyed_records = klass.destroy_all

        expect(destroyed_records.all?(&:frozen?)).to be true
      end

      it 'returns collection of records that cannot be changed (because frozen)' do
        destroyed_records = klass.destroy_all
        unable_to_change = destroyed_records.all? do |obj|
          obj.name = Faker::Lorem.words.join(' ')
          false
        rescue FrozenError => _e
          true
        end
        expect(unable_to_change).to be true
      end

      it 'succeeds when there are already no records to destroy' do
        klass.destroy_all

        allow(klass.connection)
          .to receive(:get)
          .with(path: '/v1/narratives/')
          .and_return(MockApi::Successful.empty_collection)
        expect(klass.destroy_all).to be_empty
      end
    end

    describe '.destroy_all!' do
      before { instances }

      it 'returns an Array' do
        expect(klass.destroy_all!).to be_an Array
      end

      it 'destroys each of records' do
        allow(klass.connection).to receive(:delete)

        klass.destroy_all!
        expect(klass.connection).to have_received(:delete).exactly(3).times
      end

      it 'returns an Array that is not empty' do
        expect(klass.destroy_all!).not_to be_empty
      end

      it 'returns collection of records destroyed that matches the original records' do
        skip "check that this actually works and that original records isn't just empty"

        original_records = ids.map { |id| klass.find(id) }

        destroyed_records = klass.destroy_all!
        expect(destroyed_records).to eq original_records
      end

      it 'results in no records remaining' do
        klass.destroy_all!

        allow(klass.connection)
          .to receive(:get)
          .with(path: '/v1/narratives/')
          .and_return(MockApi::Successful.empty_collection)

        expect(klass.all).to be_empty
      end

      it 'returns collection of records that are marked as destroyed' do
        destroyed_records = klass.destroy_all!
        expect(destroyed_records.all?(&:destroyed?)).to be true
      end

      it 'returns collection of records that are marked as frozen' do
        destroyed_records = klass.destroy_all!
        expect(destroyed_records.all?(&:frozen?)).to be true
      end

      it 'returns collection of records that cannot be changed (because frozen)' do
        destroyed_records = klass.destroy_all!
        unable_to_change = destroyed_records.all? do |obj|
          obj.name = Faker::Lorem.words.join(' ')
          false
        rescue FrozenError => _e
          true
        end
        expect(unable_to_change).to be true
      end

      it 'succeeds when there are already no records to destroy' do
        allow(klass.connection)
          .to receive(:get)
          .with(path: '/v1/narratives/')
          .and_return(MockApi::Successful.empty_collection)

        klass.destroy_all!
        expect(klass.destroy_all!).to be_empty
      end
    end
  end

  context 'when remote api cannot be connected to' do
    let(:arbitrary_id) { Faker::Internet.uuid }

    before do
      allow(klass.connection)
        .to receive(:get)
        .and_raise(Excon::Error::Socket.new(Errno::ECONNREFUSED.new))

      allow(klass.connection)
        .to receive(:post)
        .and_raise(Excon::Error::Socket.new(Errno::ECONNREFUSED.new))

      allow(klass.connection)
        .to receive(:delete)
        .and_raise(Excon::Error::Socket.new(Errno::ECONNREFUSED.new))
    end

    describe 'raises UnavailableHost when using' do
      it '.find' do
        expect { klass.find(arbitrary_id) }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '[]' do
        expect { klass[arbitrary_id] }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '.all' do
        expect { klass.all }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '.create' do
        expect { klass.create(attributes) }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '.create!' do
        expect { klass.create!(attributes) }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '.destroy_all' do
        expect { klass.destroy_all }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end

      it '.destroy_all!' do
        expect { klass.destroy_all! }
          .to raise_error JSONAPI::Model::Error::UnavailableHost
      end
    end
  end

  describe 'when remote api returns an unrecognized status code,' do
    subject(:request) { klass.find(Faker::Internet.uuid) }

    before do
      allow(klass.connection)
        .to receive(:get)
        .and_return(MockApi::UnrecognizedStatus.weird_status_code_of(status_code: 611))
    end

    it 'request raises RequestFailed and indicates the reason' do
      expect { request }
        .to raise_error JSONAPI::Model::Error::RequestFailed, /unrecognized_status_code/
    end

    it 'request raises RequestFailed and includes the unrecognized status code' do
      expect { request }
        .to raise_error JSONAPI::Model::Error::RequestFailed, /611/
    end
  end
end
