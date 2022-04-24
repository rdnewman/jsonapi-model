RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'instance with validations but with missing attributes' do
    subject(:object) { klass.new(attributes) }

    include_context 'for base instance'

    let(:klass)      { validating_klass }
    let(:attributes) { missing_attributes }

    describe 'upon new' do
      include_examples 'new record attributes'

      it 'is invalid' do
        expect(object.valid?).to be false
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

    context 'when saving' do
      context 'for the first time (create)' do
        describe '#save' do
          include_examples 'invalid initial save'
        end

        describe '#save!' do
          it 'raises ValidationsFailed error' do
            expect { object.save! }.to raise_error JSONAPI::Model::Error::ValidationsFailed
          end
        end
      end

      context 'for existing record (update)' do
        include_context 'for updating save when missing attributes'

        describe '#save' do
          include_examples 'saving existing record', :save
        end

        describe '#save!' do
          include_examples 'saving existing record', :save!
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
        before { object.save }

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
        before { object.save }

        it 'raises NotDestroyed error' do
          expect { object.destroy! }.to raise_error JSONAPI::Model::Error::NotDestroyed
        end
      end
    end
  end
end
