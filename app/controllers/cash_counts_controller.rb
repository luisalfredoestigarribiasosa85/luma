class CashCountsController < ApplicationController
  def index
    @counts = current_account.cash_counts.includes(:user).order(counted_on: :desc)
  end

  def create
    @date = parse_date(params[:date]) || Date.current

    if current_account.cash_counts.exists?(counted_on: @date)
      redirect_to daily_cash_reports_path(date: @date), alert: "Ya existe un arqueo para esta fecha." and return
    end

    expected = expected_cash_for(@date)
    @cash_count = current_account.cash_counts.build(
      counted_on: @date,
      expected: expected,
      counted: params[:counted],
      note: params[:note]
    )

    if @cash_count.save
      redirect_to daily_cash_reports_path(date: @date), notice: "Arqueo registrado (diferencia: #{helpers.money(@cash_count.difference)})."
    else
      redirect_to daily_cash_reports_path(date: @date), alert: "No se pudo registrar el arqueo: #{@cash_count.errors.full_messages.to_sentence}"
    end
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
