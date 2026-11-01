module Api
  module V1
    class MembershipsController < BaseController
      def index
        staff!
        render json: { data: Current.organization.memberships.includes(:user).order(:created_at).map { |member| serialize(member) } }
      end

      private

      def serialize(member)
        member.slice(:id, :role, :active).merge(user: member.user.slice(:id, :name, :email))
      end
    end
  end
end
