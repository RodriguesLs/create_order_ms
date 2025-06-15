class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def order
    token = request.headers["X-Hook-Token"]
    expected_token = ENV.fetch("ORDER_HOOK_TOKEN")

    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token.to_s)
      return head :unauthorized
    end

    # Parse do payload
    json = JSON.parse(request.body.read)
    order_id = json["OrderId"]
    account = json.dig("Origin", "Account")

    if WebhookLog.exists?(order_id: order_id, success: true)
      Rails.logger.info("Pedido #{order_id} já foi processado anteriormente.")
      return head :ok
    end

    webhook_log = WebhookLog.create!(
      order_id: order_id,
      account: account,
      payload: json.to_json
    )

    begin
      order_data = FetchOrderService.new(order_id).call

      if order_data[:status] == 'ready-for-handling'
        SendOrderService.new(order_data).call
        webhook_log.update!(success: true, http_status: 200)
        head :ok
      else
        Rails.logger.info("Pedido #{order_id} está em status impróprio. Agendando retry para daqui a 10 minutos.")
        RetryOrderJob.set(wait: 10.minutes).perform_later(order_id)
        webhook_log.update!(success: false, http_status: 202, error_message: 'Status impróprio para processamento.')
        head :accepted
      end
    rescue => e
      Rails.logger.error("Fetching order error #{order_id}: #{e.message}")

      webhook_log.update!(success: false, http_status: 502, error_message: e.message)

      head :bad_gateway
    end
  end
end
