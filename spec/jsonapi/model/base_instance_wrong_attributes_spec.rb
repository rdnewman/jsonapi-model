RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'instance with validations and with wrong attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { validating_klass }
    let(:attributes) { wrong_attributes }

    describe 'upon new' do
      it 'raises ActiveModel::UnknownAttributeError' do
        expect { object }.to raise_error ActiveModel::UnknownAttributeError
      end
    end
  end

  describe 'instance without validations and with wrong attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { unvalidating_klass }
    let(:attributes) { wrong_attributes }

    describe 'upon new' do
      it 'raises ActiveModel::UnknownAttributeError' do
        expect { object }.to raise_error ActiveModel::UnknownAttributeError
      end
    end
  end

  describe 'instance with validations but with wrong attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { unconforming_klass }
    let(:attributes) { wrong_attributes }

    describe 'upon new' do
      it 'has a name' do
        expect(object.name).to eq attributes[:name]
      end

      it 'has a bad_key' do
        expect(object.bad_key).to eq attributes[:bad_key]
      end

      it 'is valid' do
        expect(object.valid?).to eq true
      end
    end

    describe '#id=' do
      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::ClientError.bad_key)
      end

      it 'changes id for the object after an attempted #save' do
        object.save
        expect { object.id = arbitrary_id }.to change(object, :id).from(nil).to(arbitrary_id)
      end

      it 'changes id for the object after an attempted #save!' do
        begin
          object.save!
        rescue JSONAPI::Model::Error::RequestFailed
          nil
        end
        expect { object.id = arbitrary_id }.to change(object, :id).from(nil).to(arbitrary_id)
      end

      it 'prohibits #save! from being attempted' do
        object.id = arbitrary_id
        expect { object.save! }.to raise_error JSONAPI::Model::Error::ProhibitedCreation
      end
    end

    describe '#assign_attributes' do
      context 'when attributes are given' do
        let(:changed_attributes) do
          {
            bad_key: Faker::Lorem.words.join(' ')
          }
        end

        it 'does not change :name' do
          expect { object.assign_attributes(changed_attributes) }
            .not_to change(object, :name)
        end

        it 'changes :bad_key' do
          expect { object.assign_attributes(changed_attributes) }
            .to change(object, :bad_key)
        end
      end
    end

    describe '#save' do
      context 'for first time (create)' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockApi::ClientError.bad_key)
        end

        include_examples 'invalid initial save'
      end

      context 'for existing record (update)' do
        subject(:object) { klass.find(persisted_id) } # an existing object

        let(:persisted_id) do
          valid_object = validating_klass.new(valid_attributes)
          valid_object.save!
          valid_object.id
        end
        let(:changed_attributes) { wrong_attributes }

        before do
          allow(validating_klass.connection)
            .to receive(:post)
            .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))

          allow(klass.connection)
            .to receive(:put)
            .and_return(MockApi::ClientError.bad_key)

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockApi::Successful.resource(arbitrary_id, valid_attributes))

          original_object
          object.assign_attributes(changed_attributes)
        end

        it 'confirms subject was originally persisted before update attempt' do
          expect(object.persisted?).to eq true
        end

        it "confirms subject's #name is to be changed by an update attempt" do
          expect(object.name).not_to eq original_object.name
        end

        it 'confirms subject has a bad key to be updated' do
          expect(object.bad_key).not_to be_nil
        end

        it 'returns false' do
          expect(object.save).to eq false
        end

        it 'does not change id for the object' do
          expect { object.save }.not_to change(object, :id)
        end

        it 'does not change the hash' do
          expect { object.save }.not_to change(object, :hash)
        end

        it 'does not change the object from being regarded as not a new record' do
          expect { object.save }.not_to change(object, :new_record?).from(false)
        end

        it 'does not change the object from being regarded as persisted' do
          expect { object.save }.not_to change(object, :persisted?).from(true)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.save }.not_to change(object, :destroyed?).from(false)
        end

        it 'when retrieved later still contains the original data' do
          object.save
          expect(klass.find(object.id)).to eq original_object
        end
      end
    end

    describe '#save!' do
      context 'for first time (create)' do
        it 'raises RequestFailed error' do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockApi::ClientError.bad_key)

          expect { object.save! }
            .to raise_error JSONAPI::Model::Error::RequestFailed, /unprocessable_entity/
        end
      end

      context 'for existing record (update)' do
        subject(:object) { klass.find(persisted_id) } # an existing object

        let(:persisted_id) do
          valid_object = validating_klass.new(valid_attributes)
          valid_object.save!
          valid_object.id
        end

        let(:changed_attributes) { wrong_attributes }

        before do
          allow(validating_klass.connection)
            .to receive(:post)
            .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockApi::Successful.resource(arbitrary_id, valid_attributes))

          original_object
          object.assign_attributes(changed_attributes)
        end

        it 'confirms subject was originally persisted before update attempt' do
          expect(object.persisted?).to eq true
        end

        it "confirms subject's #name is to be changed by an update attempt" do
          expect(object.name).not_to eq original_object.name
        end

        it 'confirms subject has a bad key to be updated' do
          expect(object.bad_key).not_to be_nil
        end

        it 'raises RequestFailed error' do
          allow(klass.connection)
            .to receive(:put)
            .and_return(MockApi::ClientError.bad_key)

          expect { object.save! }
            .to raise_error JSONAPI::Model::Error::RequestFailed, /unprocessable_entity/
        end
      end
    end

    describe '#destroy,' do
      context 'when not persisted,' do
        include_examples 'destroying record'

        it "does not change the object's id" do
          expect { object.destroy }.not_to change(object, :id).from(nil)
        end
      end

      context 'after an attempt was made to persist it,' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockApi::ClientError.bad_key)

          object.save
        end

        include_examples 'destroying record'

        it "does not change the object's id" do
          expect { object.destroy }.not_to change(object, :id)
        end
      end
    end

    describe '#destroy!,' do
      context 'when not persisted,' do
        it 'raises NotDestroyed error' do
          expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
        end
      end

      context 'after an attempt was made to persist it,' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockApi::ClientError.bad_key)

          object.save
        end

        it 'raises NotDestroyed error' do
          expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
        end
      end
    end
  end
end
