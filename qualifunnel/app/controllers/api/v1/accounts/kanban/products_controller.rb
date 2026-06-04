# frozen_string_literal: true

class Api::V1::Accounts::Kanban::ProductsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board
  before_action :find_product, only: [:update, :destroy]

  def index
    authorize Qualifunnel::Kanban::Product
    @products = @board.products.active
    render json: @products
  end

  def create
    authorize Qualifunnel::Kanban::Product
    @product = @board.products.build(product_params)
    if @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @product, policy_class: Qualifunnel::Kanban::ProductPolicy
    if @product.update(product_params)
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product, policy_class: Qualifunnel::Kanban::ProductPolicy
    @product.destroy!
    head :no_content
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end

  def find_product
    @product = @board.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :unit_price, :description, :archived)
  end
end
