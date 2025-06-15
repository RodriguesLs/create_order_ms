class WebhookLog < ApplicationRecord
  validates :order_id, presence: true
  validates :account, presence: true
end
