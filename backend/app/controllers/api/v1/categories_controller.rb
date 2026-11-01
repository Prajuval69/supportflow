module Api
  module V1
    class CategoriesController < BaseController
      def index
        render json: { data: Current.organization.categories.order(:name).map { |c| c.slice(:id, :name, :active) } }
      end

      def create
        admin!
        category = Current.organization.categories.create!(params.require(:category).permit(:name))
        render json: { data: category.slice(:id, :name, :active) }, status: :created
      end

      def update
        admin!
        category = Current.organization.categories.find(params[:id])
        category.update!(params.require(:category).permit(:name, :active))
        render json: { data: category.slice(:id, :name, :active) }
      end
    end
  end
end
