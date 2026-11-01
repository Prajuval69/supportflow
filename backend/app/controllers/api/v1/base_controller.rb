module Api
  module V1
    class BaseController < ApplicationController
      class Forbidden < StandardError; end
      class Conflict < StandardError; end
      class BadInput < StandardError; end
      around_action :reset_context
      before_action :authenticate!
      before_action :select_organization!
      rescue_from ActiveRecord::RecordNotFound do
        error('not_found', 'Resource not found', :not_found)
      end
      rescue_from Forbidden do |e|
        error('forbidden', e.message.presence || 'Access denied', :forbidden)
      end
      rescue_from Conflict do |e|
        error('conflict', e.message, :conflict)
      end
      rescue_from BadInput, ActionController::ParameterMissing, ActionController::BadRequest do |e|
        error('bad_request', e.message, :bad_request)
      end
      rescue_from ActionController::InvalidAuthenticityToken do
        error('invalid_csrf', 'Refresh the page and try again', :forbidden)
      end
      rescue_from ActiveRecord::RecordInvalid do |e|
        error('validation', 'Please check the fields', :unprocessable_entity, e.record.errors.to_hash)
      end
      rescue_from ActiveRecord::RecordNotUnique do
        error('conflict', 'This record already exists', :conflict)
      end

      private

      def reset_context
        Current.reset
        response.set_header('Cache-Control', 'no-store')
        yield
      ensure
        Current.reset
      end

      def authenticate!
        Current.user = User.find_by(id: session[:user_id])
        error('unauthenticated', 'Please sign in', :unauthorized) unless Current.user
      end

      def select_organization!
        membership = Current.user.memberships.active.includes(:organization).find_by(organization_id: request.headers['X-Organization-ID'])
        raise ActiveRecord::RecordNotFound unless membership
        Current.membership = membership
        Current.organization = membership.organization
      end

      def staff!
        raise Forbidden, 'Staff access required' unless Current.membership.staff?
      end

      def admin!
        raise Forbidden, 'Admin access required' unless Current.membership.admin?
      end

      def ticket_scope
        TicketPolicy.new(Current.membership).scope
      end

      def find_ticket
        ticket_scope.includes(:created_by, :assignee, :category).find(params[:ticket_id] || params[:id])
      end

      def error(code, message, status, fields = nil)
        render json: { error: { code: code, message: message, fields: fields }.compact }, status: status
      end

      def paginate(scope)
        page = [Integer(params.fetch(:page, 1)), 1].max
        per_page = Integer(params.fetch(:per_page, 20)).clamp(1, 100)
        total = scope.count
        [scope.limit(per_page).offset((page - 1) * per_page),
         { page: page, per_page: per_page, total_count: total, total_pages: (total.to_f / per_page).ceil }]
      rescue ArgumentError, TypeError
        raise BadInput, 'Invalid pagination'
      end
    end
  end
end
