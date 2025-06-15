class RetryOrderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    Rails.logger.info("Tentando reprocessar o pedido #{order_id}...")

    begin
      order_data = FetchOrderService.new(order_id).call

      if order_data[:status] == 'ready-for-handling'
        SendOrderService.new(order_data).call
        WebhookLog.find_by(order_id: order_id)&.update!(success: true, http_status: 200)
        Rails.logger.info("Pedido #{order_id} processado com sucesso após retry.")
      else
        Rails.logger.info("Pedido #{order_id} ainda está em status impróprio. Retry será agendado novamente.")
        RetryOrderJob.set(wait: 10.minutes).perform_later(order_id)
      end
    rescue => e
      Rails.logger.error("Erro ao reprocessar pedido #{order_id}: #{e.message}")
      WebhookLog.find_by(order_id: order_id)&.update!(success: false, http_status: 500, error_message: e.message)
    end
  end
end
