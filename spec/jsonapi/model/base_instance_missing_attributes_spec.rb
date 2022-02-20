RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'instance with validations but with missing attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { validating_klass }
    let(:attributes) { missing_attributes }

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

      it 'is invalid' do
        expect(object.valid?).to eq false
      end
    end

    describe '#id=' do
      it 'changes id for the object after an attempted #save' do
        object.save
        expect { object.id = arbitrary_id }.to change(object, :id).from(nil).to(arbitrary_id)
      end

      it 'changes id for the object after an attempted #save!' do
        begin
          object.save!
        rescue JSONAPI::Model::Error::ValidationsFailed
          nil
        end
        expect { object.id = arbitrary_id }.to change(object, :id).from(nil).to(arbitrary_id)
      end

      it 'prohibits #save! from being attempted' do
        object.id = arbitrary_id
        expect { object.save! }.to raise_error JSONAPI::Model::Error::ProhibitedCreation
      end
    end

    describe '#save' do
      context 'for first time (create)' do
        it 'returns false' do
          expect(object.save).to eq false
        end

        it 'does not change id for the object' do
          expect { object.save }.not_to change(object, :id).from(nil)
        end

        it 'does not change the hash' do
          expect { object.save }.not_to change(object, :hash)
        end

        it 'does not change the object from being regarded as a new record' do
          expect { object.save }.not_to change(object, :new_record?).from(true)
        end

        it 'does not change the object from being regarded as not persisted' do
          expect { object.save }.not_to change(object, :persisted?).from(false)
        end

        it 'does not change the object from being regarded as not destroyed' do
          expect { object.save }.not_to change(object, :destroyed?).from(false)
        end

        it 'cannot be retrieved later' do
          object.save
          expect { klass.find(object.id) }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
        end
      end

      # TODO: this feels like it's testing the remote API's behavior, not the gems
      context 'for existing record (update)' do
        subject(:object) { klass.new(valid_attributes) } # so it can be persisted initially

        let(:changed_attributes) { missing_attributes }

        let(:original_data) do
          {
            id: Faker::Internet.uuid,
            attributes: valid_attributes
          }
        end

        let(:changed_data) do
          original_data.merge({ attributes: valid_attributes.merge(missing_attributes) })
        end

        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(
              MockApi::Successful.created_resource(original_data[:id], original_data[:attributes])
            )

          allow(klass.connection)
            .to receive(:put)
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

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
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).to eq object
        end

        it 'when retrieved later does not contain the original data' do
          object.save

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).not_to eq original_object
        end
      end
    end

    describe '#save!' do
      context 'for first time (create)' do
        it 'raises ValidationsFailed error' do
          expect { object.save! }.to raise_error JSONAPI::Model::Error::ValidationsFailed
        end
      end

      # TODO: this feels like it's testing the remote API's behavior, not the gems
      context 'for existing record (update)' do
        subject(:object) { klass.new(valid_attributes) } # so it can be persisted initially

        let(:changed_attributes) { missing_attributes }

        let(:original_data) do
          {
            id: Faker::Internet.uuid,
            attributes: valid_attributes
          }
        end

        let(:changed_data) do
          original_data.merge({ attributes: valid_attributes.merge(missing_attributes) })
        end

        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(
              MockApi::Successful.created_resource(original_data[:id], original_data[:attributes])
            )

          allow(klass.connection)
            .to receive(:put)
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

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
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

          expect(klass.find(object.id)).to eq object
        end

        it 'when retrieved later does not contain the original data' do
          object.save!

          allow(klass.connection)
            .to receive(:get)
            .and_return(MockApi::Successful.resource(changed_data[:id], changed_data[:attributes]))

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

      context 'after an attempt was made to persist it,' do
        before { object.save }

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
          expect { object.destroy }.not_to change(object, :id)
        end

        it 'can still change an attribute' do
          object.destroy
          expect { object.name = Faker::Lorem.words.join(' ') }.to change(object, :name)
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
        before { object.save }

        it 'raises NotDestroyed error' do
          expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
        end
      end
    end
  end
end