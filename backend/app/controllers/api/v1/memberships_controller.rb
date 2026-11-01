module Api
  module V1
    class MembershipsController < BaseController
      def index
        staff!
        render json: { data: Current.organization.memberships.includes(:user).order(:created_at).map { |member| serialize(member) } }
      end

      def create
        admin!
        member = ::Memberships::Manage.create(organization: Current.organization, actor: Current.user,
          attributes: params.require(:membership).permit(:email, :name, :password, :role).to_h)
        render json: { data: serialize(member) }, status: :created
      end

      def update
        admin!
        member = ::Memberships::Manage.update(organization: Current.organization, actor: Current.user, id: params[:id],
          attributes: params.require(:membership).permit(:role, :active).to_h)
        render json: { data: serialize(member) }
      end

      private

      def serialize(member)
        member.slice(:id, :role, :active).merge(user: member.user.slice(:id, :name, :email))
      end
    end
  end
end
