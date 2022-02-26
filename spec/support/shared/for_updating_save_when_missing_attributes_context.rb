RSpec.shared_context 'for updating save when missing attributes' do
  subject(:object) { klass.new(valid_attributes) } # so it can be persisted initially

  let(:changed_attributes) { missing_attributes }

  let(:original_data) do
    {
      id: arbitrary_id,
      attributes: valid_attributes
    }
  end

  let(:changed_data) do
    original_data.merge({ attributes: valid_attributes.merge(missing_attributes) })
  end
end
