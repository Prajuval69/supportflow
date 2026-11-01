module Api
  module V1
    class DashboardController < BaseController
      def summary
        render json: { data: ::Dashboard::Summary.call(ticket_scope, params) }
      end
    end
  end
end
