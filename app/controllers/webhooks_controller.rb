class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def order
    token = request.headers["X-Hook-Token"]
    expected_token = ENV.fetch("ORDER_HOOK_TOKEN")

    if ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token.to_s)
      head :ok
    else
      head :unauthorized
    end
  end
end
