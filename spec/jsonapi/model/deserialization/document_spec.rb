RSpec.describe JSONAPI::Model::Deserialization::Document do
  include_context 'for deserialization'

  describe '.deserialize' do
    context 'for ActionController::Parameters' do
      context 'for single resource' do
        let(:content) { ActionController::Parameters.new(single_resource) }

        context 'without any options' do
          it 'returns all data for the resource' do
            expect(described_class.deserialize(content))
              .to eq expected_result[:single][:resource]
          end
        end
      end

      context 'for many resources' do
        let(:content) { ActionController::Parameters.new(multiple_resources) }

        context 'using :except option' do
          it 'returns all the resources without specified data' do
            expect(described_class.deserialize(content, except: [:date, :title]))
              .to match_array expected_result[:multiple][:except_data_or_title]
          end
        end
      end
    end

    context 'for hash' do
      context 'for single resource' do
        let(:content) { single_resource }

        context 'using :only option' do
          it 'returns only the specified data' do
            expect(described_class.deserialize(content, only: :notes))
              .to eq expected_result[:single][:only_notes]
          end
        end
      end

      context 'for many resources' do
        let(:content) { multiple_resources }

        context 'using :polymorphic option' do
          it 'returns expected data for all the resources' do
            actual_result = described_class.deserialize(
              content, only: :author, polymorphic: :author
            )

            expect(actual_result)
              .to match_array expected_result[:multiple][:only_polymorphic_authors]
          end
        end
      end
    end

    context 'for invalid content' do
      let(:content) { 'for example, lone strings are not valid' }

      it 'returns an empty hash' do
        expect(described_class.deserialize(content)).to eq({})
      end
    end
  end

  describe '#deserialize' do
    subject(:document) { described_class.new(content) }

    context 'for ActionController::Parameters' do
      context 'for single resource' do
        let(:content) { ActionController::Parameters.new(single_resource) }

        context 'without any options' do
          it 'returns all data for the resource' do
            expect(document.deserialize).to eq expected_result[:single][:resource]
          end
        end

        context 'using :only option' do
          it 'returns only the specified data' do
            expect(document.deserialize(only: :notes))
              .to eq expected_result[:single][:only_notes]
          end
        end

        context 'using :except option' do
          it 'returns resource without specified data' do
            expect(document.deserialize(except: [:date, :title]))
              .to eq expected_result[:single][:except_data_or_title]
          end
        end

        context 'using :polymorphic option' do
          it 'returns expected data' do
            expect(document.deserialize(only: :author, polymorphic: :author))
              .to eq expected_result[:single][:only_polymorphic_author]
          end
        end
      end

      context 'for many resources' do
        let(:content) { ActionController::Parameters.new(multiple_resources) }

        context 'without any options' do
          it 'returns all data for all the resources' do
            expect(document.deserialize)
              .to match_array expected_result[:multiple][:resources]
          end
        end

        context 'using :only option' do
          it 'returns only the specified data for all the resources' do
            expect(document.deserialize(only: :notes))
              .to match_array expected_result[:multiple][:only_notes]
          end
        end

        context 'using :except option' do
          it 'returns all the resources without specified data' do
            expect(document.deserialize(except: [:date, :title]))
              .to match_array expected_result[:multiple][:except_data_or_title]
          end
        end

        context 'using :polymorphic option' do
          it 'returns expected data for all the resources' do
            expect(document.deserialize(only: :author, polymorphic: :author))
              .to match_array expected_result[:multiple][:only_polymorphic_authors]
          end
        end
      end
    end

    context 'for hash' do
      context 'for single resource' do
        let(:content) { single_resource }

        context 'without any options' do
          it 'returns all data for the resource' do
            expect(document.deserialize).to eq expected_result[:single][:resource]
          end
        end

        context 'using :only option' do
          it 'returns only the specified data' do
            expect(document.deserialize(only: :notes))
              .to eq expected_result[:single][:only_notes]
          end
        end

        context 'using :except option' do
          it 'returns resource without specified data' do
            expect(document.deserialize(except: [:date, :title]))
              .to eq expected_result[:single][:except_data_or_title]
          end
        end

        context 'using :polymorphic option' do
          it 'returns expected data' do
            expect(document.deserialize(only: :author, polymorphic: :author))
              .to eq expected_result[:single][:only_polymorphic_author]
          end
        end
      end

      context 'for many resources' do
        let(:content) { multiple_resources }

        context 'without any options' do
          it 'returns all data for all the resources' do
            expect(document.deserialize)
              .to match_array expected_result[:multiple][:resources]
          end
        end

        context 'using :only option' do
          it 'returns only the specified data for all the resources' do
            expect(document.deserialize(only: :notes))
              .to match_array expected_result[:multiple][:only_notes]
          end
        end

        context 'using :except option' do
          it 'returns all the resources without specified data' do
            expect(document.deserialize(except: [:date, :title]))
              .to match_array expected_result[:multiple][:except_data_or_title]
          end
        end

        context 'using :polymorphic option' do
          it 'returns expected data for all the resources' do
            expect(document.deserialize(only: :author, polymorphic: :author))
              .to match_array expected_result[:multiple][:only_polymorphic_authors]
          end
        end
      end
    end

    context 'for invalid content' do
      let(:content) { 'for example, lone strings are not valid' }

      it 'returns an empty hash' do
        expect(document.deserialize).to eq({})
      end
    end
  end
end
