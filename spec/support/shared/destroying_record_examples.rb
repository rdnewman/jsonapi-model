RSpec.shared_examples 'destroying record' do
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

  it 'can still change an attribute' do
    object.destroy
    expect { object.name = Faker::Lorem.words.join(' ') }.to change(object, :name)
  end
end
