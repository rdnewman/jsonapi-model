RSpec.shared_examples 'saving existing record' do |method|
  # `object` and `klass` must already be defined where these examples are included
  # NOTE: only appropriate for #save, NOT #save!

  # ex.: when method is `:save`, then
  #   `object.send(method)` is the same as `object.save`

  before do
    allow(klass.connection)
      .to receive(:post)
      .and_return(
        MockApi::Successful.created_resource(original_data[:id], original_data[:attributes])
      )

    allow(klass.connection)
      .to receive(:put)
      .and_return(
        MockApi::Successful.resource(changed_data[:id], changed_data[:attributes])
      )

    # ensure record was previously saved
    object.send(method)

    # copy the original record away for safekeeping and change attributes to be saved
    original_object
    object.assign_attributes(changed_attributes)
  end

  it 'returns true' do
    expect(object.send(method)).to be true
  end

  it 'does not change id for the object' do
    expect { object.send(method) }.not_to change(object, :id)
  end

  it 'does not change the hash' do
    expect { object.send(method) }.not_to change(object, :hash)
  end

  it 'does not change the object from being regarded as not a new record' do
    expect { object.send(method) }.not_to change(object, :new_record?).from(false)
  end

  it 'does not change the object from being regarded as persisted' do
    expect { object.send(method) }.not_to change(object, :persisted?).from(true)
  end

  it 'does not change the object from being regarded as not destroyed' do
    expect { object.send(method) }.not_to change(object, :destroyed?).from(false)
  end

  context 'when retrieved later' do
    before do
      # ensure changed attributes are saved (just as the specs above did)
      object.send(method)

      # ensure mock API returns the changed record
      # NOTE: the specs are intended to ensure the local client responds
      #   accordingly, NOT that the remote API behaved properly
      allow(klass.connection)
        .to receive(:get)
        .and_return(
          MockApi::Successful.resource(changed_data[:id], changed_data[:attributes])
        )
    end

    it 'has the updated changes' do
      expect(klass.find(object.id)).to eq object
    end

    it 'does not contain the original data' do
      expect(klass.find(object.id)).not_to eq original_object
    end
  end
end
