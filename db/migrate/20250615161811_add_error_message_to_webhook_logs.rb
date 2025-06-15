class AddErrorMessageToWebhookLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :webhook_logs, :error_message, :string
  end
end
