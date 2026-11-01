module Api
  module V1
    class SlaPoliciesController < BaseController
      def index
        render json: { data: Current.organization.sla_policies.order(:priority).map { |p| serialize(p) } }
      end

      def update
        admin!
        policy = Current.organization.sla_policies.find_by!(priority: params[:priority])
        policy.with_lock do
          policy.update!(params.require(:sla_policy).permit(:first_response_minutes, :resolution_minutes))
          Current.organization.audit_events.create!(actor: Current.user, event_type: 'sla_policy_updated',
            metadata: policy.slice(:priority, :first_response_minutes, :resolution_minutes))
        end
        render json: { data: serialize(policy) }
      end

      private

      def serialize(policy)
        policy.slice(:priority, :first_response_minutes, :resolution_minutes)
      end
    end
  end
end
