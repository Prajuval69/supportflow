require 'rails_helper'
RSpec.describe 'Concurrent PostgreSQL ticket numbering', type: :model do
  self.use_transactional_tests = false
  include ApiHelpers
  it 'serializes concurrent creators without duplicate numbers' do
    org = create_org("concurrent-#{SecureRandom.hex(4)}")
    user = create_user("concurrent#{SecureRandom.hex(4)}")
    org.memberships.create!(user: user, role: 'customer')
    threads = 8.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Tickets::Create.call(organization: Organization.find(org.id), actor: User.find(user.id),
            attributes: { title: "Concurrent #{index}", description: 'Real concurrent PostgreSQL transaction' }).ticket_number
        end
      end
    end
    numbers = threads.map(&:value)
    expect(numbers.uniq.length).to eq(8)
    expect(org.reload.ticket_sequence).to eq(8)
    expect(org.tickets.count).to eq(8)
  ensure
    if org
      TicketEvent.where(organization_id: org.id).delete_all
      Ticket.where(organization_id: org.id).delete_all
      Membership.where(organization_id: org.id).delete_all
      SlaPolicy.where(organization_id: org.id).delete_all
      org.delete
    end
    user&.delete
  end
end
