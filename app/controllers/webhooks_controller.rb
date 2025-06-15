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

    webhook_log = WebhookLog.create!(
      order_id: order_id,
      account: account,
      payload: json.to_json
    )

    begin
      order_data = FetchOrderService.new(order_id).call

      SendOrderService.new(order_data).call

      webhook_log.update!(success: true, http_status: 200)

      head :ok
    rescue => e
      Rails.logger.error("Fetching order error #{order_id}: #{e.message}")

      webhook_log.update!(success: false, http_status: 502, error_message: e.message)

      head :bad_gateway
    end
  end
end
