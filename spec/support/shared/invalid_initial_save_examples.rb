RSpec.shared_examples 'invalid initial save' do
  # `object` and `klass` must already be defined where these examples are included
  # NOTE: only appropriate for #save, NOT #save!

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

    expect { klass.find(object.id) }
      .to raise_error JSONAPI::Model::Error::InvalidIdArgument
  end
end
