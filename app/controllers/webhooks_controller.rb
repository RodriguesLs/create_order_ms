class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def order
    token = request.headers["X-Hook-Token"]
    expected_token = ENV.fetch("ORDER_HOOK_TOKEN")

    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token.to_s)
      head :unauthorized
      return
    end

    # Parse do payload
    json = JSON.parse(request.body.read)
    order_id = json["OrderId"]
    account = json.dig("Origin", "Account")

    WebhookLog.create!(
      order_id: order_id,
      account: account,
      payload: json.to_json,
      http_status: 200, # temporário, atualizaremos com status real depois
      success: true
    )

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end
end
