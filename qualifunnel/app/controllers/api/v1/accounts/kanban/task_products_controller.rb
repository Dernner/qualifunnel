# frozen_string_literal: true

class Api::V1::Accounts::Kanban::TaskProductsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_task
  before_action :find_task_product, only: [:update, :destroy]

  def index
    @task_products = @task.task_products.includes(:product)
    render json: @task_products
  end

  def create
    product = @task.board.products.find(params[:task_product][:product_id])
    @task_product = @task.task_products.build(task_product_params.merge(product: product))
    if @task_product.save
      render json: @task_product, status: :created
    else
      render json: { errors: @task_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task_product.update(task_product_params)
      render json: @task_product
    else
      render json: { errors: @task_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task_product.destroy!
    head :no_content
  end

  private

  def find_task
    @task = Current.account.kanban_tasks.find(params[:task_id])
  end

  def find_task_product
    @task_product = @task.task_products.find(params[:id])
  end

  def task_product_params
    params.require(:task_product).permit(:product_id, :quantity, :unit_price, :discount_percentage)
  end
end
