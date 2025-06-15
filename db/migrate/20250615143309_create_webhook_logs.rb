class CreateWebhookLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_logs do |t|
      t.string :order_id
      t.string :account
      t.text :payload
      t.integer :http_status
      t.boolean :success

      t.timestamps

    end

    add_index :webhook_logs, :order_id
    add_index :webhook_logs, :account
  end
end
