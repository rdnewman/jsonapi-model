RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'instance with validations and with required attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { validating_klass }
    let(:attributes) { valid_attributes }

    describe 'upon new' do
      include_examples 'new record attributes'

      it 'is valid' do
        expect(object.valid?).to be true
      end
    end

    describe '#id=' do
      it 'raises FrozenError once object is persisted' do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))
        object.save

        expect { object.id = Faker::Internet.uuid }.to raise_error FrozenError
      end

      it 'prohibits #save' do
        object.id = arbitrary_id

        expect(object.save).to be false
      end

      it 'prohibits #save!' do
        object.id = arbitrary_id

        expect { object.save! }.to raise_error JSONAPI::Model::Error::ProhibitedCreation
      end
    end

    context 'when saving' do
      before do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))
      end

      context 'for first time (create)' do
        shared_examples 'saving new record' do |method|
          # ex.: when method is `:save`, then
          #   `object.send(method)` is the same as `object.save`

          it 'returns true' do
            expect(object.send(method)).to be true
          end

          it 'changes id for the object' do
            expect { object.send(method) }.to change(object, :id).from(nil)
          end

          it 'changes the hash' do
            expect { object.send(method) }.to change(object, :hash)
          end

          it 'changes object to no longer being regarded as a new record' do
            expect { object.send(method) }.to change(object, :new_record?).from(true).to(false)
          end

          it 'changes object to now being regarded as persisted' do
            expect { object.send(method) }.to change(object, :persisted?).from(false).to(true)
          end

          it 'does not change the object from being regarded as not destroyed' do
            expect { object.send(method) }.not_to change(object, :destroyed?).from(false)
          end

          it 'can be retrieved later' do
            object.send(method)

            allow(klass.connection)
              .to receive(:get)
              .and_return(MockApi::Successful.resource(arbitrary_id, valid_attributes))

            expect(klass.find(object.id)).to eq object
          end
        end

        describe '#save' do
          include_examples 'saving new record', :save
        end

        describe '#save!' do
          include_examples 'saving new record', :save!
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

        describe '#save' do
          include_examples 'saving existing record', :save
        end

        describe '#save!' do
          include_examples 'saving existing record', :save!
        end
      end
    end

    context 'when destroying' do
      context 'when not persisted,' do
        describe '#destroy' do
          it 'returns false' do
            expect(object.destroy).to be false
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

        describe '#destroy!' do
          it 'raises NotDestroyed error' do
            expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
          end
        end
      end

      context 'when already persisted,' do
        before do
          allow(klass.connection)
            .to receive(:post)
            .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))

          allow(klass.connection)
            .to receive(:delete)
            .and_return(MockApi::Successful.resource(arbitrary_id, valid_attributes))

          object.save
        end

        shared_examples 'destroying persisted record' do |method|
          # ex.: when method is `:destroy`, then
          #   `object.send(method)` is the same as `object.destroy`

          it 'returns true' do
            expect(object.send(method)).to be true
          end

          it 'does not change the object from being regarded as not a new record' do
            expect { object.send(method) }.not_to change(object, :new_record?).from(false)
          end

          it 'changes object to no longer being regarded as persisted' do
            expect { object.send(method) }.to change(object, :persisted?).from(true).to(false)
          end

          it 'changes object to now being regarded as destroyed' do
            expect { object.send(method) }.to change(object, :destroyed?).from(false).to(true)
          end

          it "does not change the object's id" do
            expect { object.send(method) }.not_to change(object, :id)
          end

          it 'cannot be retrieved later' do
            object.send(method)

            allow(klass.connection)
              .to receive(:get)
              .and_return(MockApi::ClientError.not_found)

            expect { klass.find(object.id) }.to raise_error JSONAPI::Model::Error::NotFound
          end

          it 'prohibits later changes to an attribute' do
            object.send(method)
            expect { object.name = Faker::Lorem.words.join(' ') }.to raise_error FrozenError
          end
        end

        describe '#destroy' do
          include_examples 'destroying persisted record', :destroy
        end

        describe '#destroy!' do
          include_examples 'destroying persisted record', :destroy!
        end
      end
    end
  end
end
