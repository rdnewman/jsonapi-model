RSpec.describe JSONAPI::Model::Base, type: :model do
  describe 'any instance' do
    subject(:object) { klass.new(valid_attributes) }

    include_context 'for base instance'

    let(:klass) { validating_klass }

    context 'when missing "use_host"' do
      subject(:object) { klass.new }

      let(:klass) do
        Class.new(described_class) do
          use_endpoint '/v1/narratives/'
          serialize_as :narrative
        end
      end

      it '#connection fails' do
        expect { object.connection }.to raise_error JSONAPI::Model::Error::NoHostDefined
      end
    end

    context 'when "use_host" specifies an invalid host' do
      subject(:object) { klass.new }

      let(:klass) do
        Class.new(described_class) do
          use_host 'malformed url'
          use_endpoint '/v1/narratives/'
          serialize_as :narrative
        end
      end

      it '#connection fails' do
        expect { object.connection }.to raise_error JSONAPI::Model::Error::InvalidHost
      end
    end

    context 'when missing "serialize_as"' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'http://127.0.0.1:3000'
          use_endpoint '/v1/narratives/'

          attr_accessor :name, :short_description, :description, :submission_details
        end
      end

      it '.save! fails' do
        expect { klass.new(valid_attributes).save! }
          .to raise_error JSONAPI::Model::Error::NoSerializationTypeDefined
      end
    end

    context 'when "serialize_as" specifies an invalid type' do
      let(:klass) do
        Class.new(described_class) do
          use_host 'http://127.0.0.1:3000'
          use_endpoint '/v1/narratives/'
          serialize_as :bad_type

          attr_accessor :name, :short_description, :description, :submission_details
        end
      end

      it '.save! fails' do
        allow(klass.connection)
          .to receive(:post)
          .and_return(MockApi::ClientError.bad_type)

        expect { klass.new(valid_attributes).save! }
          .to raise_error JSONAPI::Model::Error::RequestFailed, /unprocessable_entity/
      end
    end

    describe 'upon new' do
      it 'is a new record' do
        expect(object.new_record?).to eq true
      end

      it 'is not persisted' do
        expect(object.persisted?).to eq false
      end

      it 'is not destroyed' do
        expect(object.destroyed?).to eq false
      end

      it 'has no id' do
        expect(object.id).to be_nil
      end

      it 'cannot be found with its id' do
        expect { klass.find(object.id) }.to raise_error JSONAPI::Model::Error::InvalidIdArgument
      end

      it 'generates a hash as an Integer' do
        expect(object.hash).to be_an Integer
      end

      it 'generates a hash that is not zero' do
        expect(object.hash).not_to be_zero
      end
    end

    describe '#id=' do
      it 'returns assigned id' do
        expect(object.id = arbitrary_id).to eq arbitrary_id
      end

      it 'changes id for the object' do
        expect { object.id = arbitrary_id }.to change(object, :id).from(nil).to(arbitrary_id)
      end

      it 'changes hash for the object' do
        expect { object.id = arbitrary_id }.to change(object, :hash)
      end
    end

    describe '#assign_attributes' do
      context 'when a subset of attributes is given' do
        let(:changed_attributes) do
          {
            name: Faker::Lorem.words.join(' '),
            # short_description: Faker::Lorem.words.join(' '),
            description: Faker::Lorem.words.join(' '),
            submission_details: Faker::Lorem.words.join(' ')
          }
        end

        it 'changes :name' do
          expect { object.assign_attributes(changed_attributes) }
            .to change(object, :name)
        end

        it 'does not change :short_description' do
          expect { object.assign_attributes(changed_attributes) }
            .not_to change(object, :short_description)
        end

        it 'changes :description' do
          expect { object.assign_attributes(changed_attributes) }
            .to change(object, :description)
        end

        it 'changes :submission_details' do
          expect { object.assign_attributes(changed_attributes) }
            .to change(object, :submission_details)
        end
      end
    end

    describe 'equality' do
      describe 'using #==' do
        it 'matches itself' do
          # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
          expect(object == object).to eq true
          # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands
        end

        it 'does not match a different set of attributes' do
          other_object = klass.new(
            {
              name: Faker::Lorem.words.join(' '),
              short_description: Faker::Lorem.words.join(' '),
              description: Faker::Lorem.words.join(' '),
              submission_details: Faker::Lorem.words.join(' ')
            }
          )

          expect(object == other_object).to eq false
        end

        context 'after saving' do
          let(:object_after_saving) do
            copy_of_object = object.clone
            copy_of_object.save!
            copy_of_object
          end

          before do
            allow(object.connection)
              .to receive(:post)
              .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))
          end

          it 'confirms persistence does not match between before-saved and after-saved versions' do
            expect(object.persisted?).not_to eq object_after_saving.persisted?
          end

          it 'does not match after saving because ids do not match' do
            expect(object == object_after_saving).to eq false
          end

          it 'matches a copy of itself if the ids match' do
            object.id = object_after_saving.id
            expect(object == object_after_saving).to eq true
          end
        end
      end

      describe 'using #eql?' do
        it 'matches itself' do
          expect(object.eql?(object)).to eq true
        end

        it 'does not match a different set of attributes' do
          other_object = klass.new(
            {
              name: Faker::Lorem.words.join(' '),
              short_description: Faker::Lorem.words.join(' '),
              description: Faker::Lorem.words.join(' '),
              submission_details: Faker::Lorem.words.join(' ')
            }
          )

          expect(object.eql?(other_object)).to eq false
        end

        context 'after saving' do
          let(:object_after_saving) do
            copy_of_object = object.clone
            copy_of_object.save!
            copy_of_object
          end

          before do
            allow(object.connection)
              .to receive(:post)
              .and_return(MockApi::Successful.created_resource(arbitrary_id, valid_attributes))
          end

          it 'confirms persistence does not match between before-saved and after-saved versions' do
            expect(object.persisted?).not_to eq object_after_saving.persisted?
          end

          it 'does not match after saving because ids do not match' do
            expect(object.eql?(object_after_saving)).to eq false
          end

          it 'matches a copy of itself if the ids match' do
            object.id = object_after_saving.id
            expect(object.eql?(object_after_saving)).to eq true
          end
        end
      end
    end

    describe '#freeze' do
      it "prevents changes to the object's id" do
        object.freeze
        expect { object.id = arbitrary_id }.to raise_error FrozenError
      end

      it "prevents changes to the object's name" do
        object.freeze
        expect { object.name = Faker::Lorem.words.join(' ') }.to raise_error FrozenError
      end

      it 'prevents changes via #assign_attributes' do
        object.freeze
        expect { object.assign_attributes(description: Faker::Lorem.words.join(' ')) }
          .to raise_error FrozenError
      end

      it 'prevents #save' do
        object.freeze
        expect { object.save }.to raise_error FrozenError
      end

      it 'prevents #save!' do
        object.freeze
        expect { object.save! }.to raise_error FrozenError
      end
    end

    describe '#frozen?' do
      it 'is false if #freeze not yet called on the object' do
        expect(object.frozen?).to eq false
      end

      it 'is true if #freeze has been called on the object' do
        object.freeze
        expect(object.frozen?).to eq true
      end
    end
  end
end
