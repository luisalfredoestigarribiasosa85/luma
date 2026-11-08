class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[ edit update destroy ]

  def index
    @from = parse_date(params[:from]) || Date.current.beginning_of_month
    @to   = parse_date(params[:to]) || Date.current
    @from, @to = @to, @from if @from > @to
    @category = params[:category].presence_in(Expense::CATEGORIES)

    expenses = current_account.expenses.where(spent_on: @from..@to)
    expenses = expenses.where(category: @category) if @category

    @expenses = expenses.order(spent_on: :desc, created_at: :desc)
    @total = expenses.sum(:amount).to_d
  end

  def new
    @expense = current_account.expenses.build(payment_method: :cash)
  end

  def create
    @expense = current_account.expenses.build(expense_params)

    if @expense.save
      redirect_to expenses_path, notice: "Gasto registrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Gasto actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy!
    redirect_to expenses_path, notice: "Gasto eliminado."
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid
    redirect_to expenses_path, alert: "No se pudo eliminar el gasto."
  end

  private

  def set_expense
    @expense = current_account.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:description, :category, :amount, :spent_on, :payment_method, :note)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
