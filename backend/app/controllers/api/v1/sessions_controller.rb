module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate!, only: [:health, :csrf, :login]
      skip_before_action :select_organization!
      def health = render(json: { data: { status: 'ok', service: 'supportflow' } })
      def csrf = render(json: { data: { csrf_token: form_authenticity_token } })

      def login
        user = User.find_by(email: params[:email].to_s.strip.downcase)
        if user&.authenticate(params[:password].to_s)
          reset_session
          session[:user_id] = user.id
          Current.user = user
          render json: { data: identity.merge(csrf_token: form_authenticity_token) }
        else
          error('invalid_credentials', 'Email or password is incorrect', :unauthorized)
        end
      end

      def logout
        reset_session
        head :no_content
      end

      def me = render(json: { data: identity })
      def organizations = render(json: { data: identity[:memberships] })

      private

      def identity
        { user: Current.user.slice(:id, :name, :email),
          memberships: Current.user.memberships.active.includes(:organization).order(:created_at).map do |m|
            { id: m.id, role: m.role, organization: m.organization.slice(:id, :name, :slug) }
          end }
      end
    end
  end
end
