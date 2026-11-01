require 'rails_helper'
RSpec.describe User, type: :model do
  it 'normalizes email, hashes passwords and rejects duplicates' do
    user = User.create!(name: 'Test Person', email: '  PERSON@EXAMPLE.COM ', password: 'TestPassword!123')
    expect(user.email).to eq('person@example.com')
    expect(user.password_digest).not_to eq('TestPassword!123')
    expect(user.authenticate('TestPassword!123')).to eq(user)
    expect(User.new(name: 'Copy', email: 'PERSON@example.com', password: 'TestPassword!123')).not_to be_valid
  end

  it 'enforces unique organization membership' do
    user = User.create!(name: 'Member', email: 'member@example.com', password: 'TestPassword!123')
    org = Organization.create!(name: 'Example', slug: 'example')
    org.memberships.create!(user: user, role: 'customer')
    expect(org.memberships.build(user: user, role: 'agent')).not_to be_valid
  end
end
