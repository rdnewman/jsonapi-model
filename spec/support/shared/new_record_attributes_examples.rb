RSpec.shared_examples 'new record attributes' do
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
end
