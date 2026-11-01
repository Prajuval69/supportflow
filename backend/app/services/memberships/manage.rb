module Memberships
  class Manage
    def self.create(organization:, actor:, attributes:)
      member = nil
      organization.with_lock do
        attrs = attributes.symbolize_keys
        email = attrs[:email].to_s.strip.downcase
        user = User.find_by(email: email)
        user ||= User.create!(name: attrs[:name], email: email, password: attrs[:password])
        member = organization.memberships.create!(user: user, role: attrs.fetch(:role, 'customer'))
        organization.audit_events.create!(actor: actor, event_type: 'membership_created', metadata: { membership_id: member.id, role: member.role })
      end
      member
    end

    def self.update(organization:, actor:, id:, attributes:)
      member = nil
      organization.with_lock do
        member = organization.memberships.find(id)
        member.assign_attributes(attributes)
        if member.role_in_database == 'admin' && member.active_in_database && (!member.active? || !member.admin?) &&
            organization.memberships.active.where(role: 'admin').count <= 1
          raise Api::V1::BaseController::Conflict, 'The last active admin cannot be removed'
        end
        changes = member.changes.slice('role', 'active')
        member.save!
        organization.audit_events.create!(actor: actor, event_type: 'membership_updated', metadata: { membership_id: member.id, changes: changes })
      end
      member
    end
  end
end
