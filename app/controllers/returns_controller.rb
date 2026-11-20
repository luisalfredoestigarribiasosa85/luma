class ReturnsController < ApplicationController
  def new
    @sale = current_account.sales.completed.find(params[:sale_id])
    @return = @sale.returns.build
    # Una línea por cada producto de la venta con cantidad restante devolvible.
    @sale.items.each do |item|
      remaining = item.quantity - ReturnItem.joins(:return)
        .where("returns.sale_id = ?", @sale.id)
        .where(product_id: item.product_id)
        .sum(:quantity)
      next if remaining <= 0

      @return.items.build(product: item.product, quantity: remaining, unit_price: item.unit_price)
    end
  end

  def create
    @sale = current_account.sales.completed.find(params[:sale_id])
    @return = @sale.returns.build(return_params)

    if @return.save
      redirect_to @sale, notice: "Devolución registrada (#{helpers.money(@return.amount)})."
    else
      # Reconstruir los campos del formulario.
      @return.errors.add(:base, "No se pudo registrar la devolución") if @return.items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def return_params
    params.require(:return).permit(:refund_method, :note,
                                   items_attributes: %i[ product_id quantity unit_price ])
  end
end
