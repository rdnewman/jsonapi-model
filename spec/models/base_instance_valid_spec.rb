RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'instance with validations and with required attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { validating_klass }
    let(:attributes) { valid_attributes }

    describe 'upon new' do
      it 'has a name' do
        expect(object.name).to eq attributes[:name]
      end

      it 'has a description' do
        expect(object.description).to eq attributes[:description]
      end

      it 'has a short description' do
        expect(object.short_description).to eq attributes[:short_description]
      end

      it 'has submission details' do
        expect(object.submission_details).to eq attributes[:submission_details]
      end

      it 'is valid' do
        expect(object.valid?).to eq true
      end
    end

    describe '#id=' do
      it 'raises FrozenError once object is persisted' do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockSuccessful.created_resource(arbitrary_id, valid_attributes))
        object.save

        expect { object.id = Faker::Internet.uuid }.to raise_error FrozenError
      end

      it 'prohibits #save' do
        object.id = arbitrary_id

        expect(object.save).to eq false
      end

      it 'prohibits #save!' do
        object.id = arbitrary_id

        expect { object.save! }.to raise_error JSONAPI::Model::Error::ProhibitedCreation
      end
    end

    describe '#save' do
      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockSuccessful.created_resource(arbitrary_id, valid_attributes))
      end

      context 'for first time (create)' do
        it 'returns true' do
          expect(object.save).to eq true
        end

        it 'changes id for the object' do
          expect { object.save }.to change(object, :id).from(nil)
        end

        it 'changes the hash' do
          expect { object.save }.to change(object, :hash)
        end

        it 'changes object to no longer being regarded as a new record' do
          expect { object.save }.to change(object, :new_record?).from(true).to(false)
        end

        it 'changes object to now being regarded as persisted' do
          expect { object.save }.to change(object, :persisted?).from(false).to(true)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.save }.not_to change(object, :destroyed?).from(false)
        end

        it 'can be retrieved later' do
          object.save

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(arbitrary_id, valid_attributes))

          expect(klass.find(object.id)).to eq object
        end
      end

      context 'for existing record (update)' do
        let(:original_data) do
          {
            id: arbitrary_id,
            attributes: valid_attributes
          }
        end

        let(:changed_data) do
          original_data.merge({ attributes: valid_attributes.merge(changed_attributes) })
        end

        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockSuccessful.created_resource(original_data[:id], original_data[:attributes]))

          allow(klass.connection)
            .to receive(:put)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          object.save
          original_object
          object.assign_attributes(changed_attributes)
        end

        it 'returns true' do
          expect(object.save).to eq true
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

        it 'can be retrieved later with the updated changes' do
          object.save

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).to eq object
        end

        it 'when retrieved later does not contain the original data' do
          object.save

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).not_to eq original_object
        end
      end
    end

    describe '#save!' do
      context 'for first time (create!)' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockSuccessful.created_resource(arbitrary_id, valid_attributes))
        end

        it 'returns true' do
          expect(object.save!).to eq true
        end

        it 'changes id for the object' do
          expect { object.save }.to change(object, :id).from(nil)
        end

        it 'changes the hash' do
          expect { object.save }.to change(object, :hash)
        end

        it 'changes object to no longer being regarded as a new record' do
          expect { object.save }.to change(object, :new_record?).from(true).to(false)
        end

        it 'changes object to now being regarded as persisted' do
          expect { object.save }.to change(object, :persisted?).from(false).to(true)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.save }.not_to change(object, :destroyed?).from(false)
        end

        it 'can be retrieved later' do
          object.save!

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(arbitrary_id, valid_attributes))

          expect(klass.find(object.id)).to eq object
        end
      end

      context 'for existing record (update!)' do
        let(:original_data) do
          {
            id: Faker::Internet.uuid,
            attributes: valid_attributes
          }
        end

        let(:changed_data) do
          original_data.merge({ attributes: valid_attributes.merge(changed_attributes) })
        end

        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockSuccessful.created_resource(original_data[:id], original_data[:attributes]))

          allow(klass.connection)
            .to receive(:put)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          object.save!
          original_object
          object.assign_attributes(changed_attributes)
        end

        it 'returns true' do
          expect(object.save!).to eq true
        end

        it 'does not change id for the object' do
          expect { object.save! }.not_to change(object, :id)
        end

        it 'does not change the hash' do
          expect { object.save! }.not_to change(object, :hash)
        end

        it 'does not change the object from being regarded as not a new record' do
          expect { object.save! }.not_to change(object, :new_record?).from(false)
        end

        it 'does not change the object from being regarded as persisted' do
          expect { object.save! }.not_to change(object, :persisted?).from(true)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.save! }.not_to change(object, :destroyed?).from(false)
        end

        it 'can be retrieved later with the updated changes' do
          object.save!

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).to eq object
        end

        it 'when retrieved later does not contain the original data' do
          object.save!

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockSuccessful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).not_to eq original_object
        end
      end
    end

    describe '#destroy,' do
      context 'when not persisted,' do
        it 'returns false' do
          expect(object.destroy).to eq false
        end

        it 'does not change the object from being regarded as a new record' do
          expect { object.destroy }.not_to change(object, :new_record?).from(true)
        end

        it 'does not change the object from being regarded as not persisted' do
          expect { object.destroy }.not_to change(object, :persisted?).from(false)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.destroy }.not_to change(object, :destroyed?).from(false)
        end

        it "does not change the object's id" do
          expect { object.destroy }.not_to change(object, :id).from(nil)
        end

        it 'can still change an attribute' do
          object.destroy
          expect { object.name = Faker::Lorem.words.join(' ') }.to change(object, :name)
        end
      end

      context 'when already persisted,' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockSuccessful.created_resource(arbitrary_id, valid_attributes))

          allow(klass.connection)
            .to receive(:delete)
            .and_return(MockSuccessful.resource(arbitrary_id, valid_attributes))

          object.save
        end

        it 'returns true' do
          expect(object.destroy).to eq true
        end

        it 'does not change the object from being regarded as not a new record' do
          expect { object.destroy }.not_to change(object, :new_record?).from(false)
        end

        it 'changes object to no longer being regarded as persisted' do
          expect { object.destroy }.to change(object, :persisted?).from(true).to(false)
        end

        it 'changes object to now being regarded as destroyed' do
          expect { object.destroy }.to change(object, :destroyed?).from(false).to(true)
        end

        it "does not change the object's id" do
          expect { object.destroy }.not_to change(object, :id)
        end

        it 'cannot be retrieved later' do
          object.destroy

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockClientError.not_found)

          expect { klass.find(object.id) }.to raise_error JSONAPI::Model::Error::NotFound
        end

        it 'prohibits later changes to an attribute' do
          object.destroy
          expect { object.name = Faker::Lorem.words.join(' ') }.to raise_error FrozenError
        end
      end
    end

    describe '#destroy!,' do
      context 'when not persisted,' do
        it 'raises NotDestroyed error' do
          expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
        end
      end

      context 'when already persisted,' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockSuccessful.created_resource(arbitrary_id, valid_attributes))

          allow(klass.connection)
            .to receive(:delete)
            .and_return(MockSuccessful.resource(arbitrary_id, valid_attributes))

          object.save
        end

        it 'returns true' do
          expect(object.destroy!).to eq true
        end

        it 'does not change the object from being regarded as not a new record' do
          expect { object.destroy! }.not_to change(object, :new_record?).from(false)
        end

        it 'changes object to no longer being regarded as persisted' do
          expect { object.destroy! }.to change(object, :persisted?).from(true).to(false)
        end

        it 'changes object to now being regarded as destroyed' do
          expect { object.destroy! }.to change(object, :destroyed?).from(false).to(true)
        end

        it "does not change the object's id" do
          expect { object.destroy! }.not_to change(object, :id)
        end

        it 'cannot be retrieved later' do
          object.destroy!

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockClientError.not_found)

          expect { klass.find(object.id) }.to raise_error JSONAPI::Model::Error::NotFound
        end

        it 'prohibits later changes to an attribute' do
          object.destroy!
          expect { object.name = Faker::Lorem.words.join(' ') }.to raise_error FrozenError
        end
      end
    end
  end
end
