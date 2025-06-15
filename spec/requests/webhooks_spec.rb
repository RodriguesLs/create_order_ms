# spec/requests/webhooks_spec.rb
require 'rails_helper'

RSpec.describe 'Order Webhooks', type: :request do
  let(:valid_token) { ENV.fetch("ORDER_HOOK_TOKEN", "meu_token_super_secreto") }
  let(:headers) do
    {
      'Content-Type': 'application/json',
      'X-Hook-Token': valid_token
    }
  end

  let(:valid_payload) do
    {
      OrderId: '1538830588318-01',
      Origin: {
        Account: 'grupoxpto'
      }
    }.to_json
  end

  describe 'POST /webhooks/order' do
    before do
      stub_request(:get, "https://external-service.test/orders/1538830588318-01")
        .to_return(status: 200, body: { id: '1538830588318-01', status: 'ready-for-handling', customer_name: 'John Doe', items: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
      allow(SendOrderService).to receive(:new).and_return(double(call: true))
    end

    context 'with valid token' do
      it 'returns 200 OK' do
        post '/webhooks/order', params: valid_payload, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'create a WebhookLog with received data' do
        expect {
          post '/webhooks/order', params: valid_payload, headers: headers
        }.to change(WebhookLog, :count).by(1)

        log = WebhookLog.last
        expect(log.order_id).to eq("1538830588318-01")
        expect(log.account).to eq("grupoxpto")
        expect(log.success).to eq(true)
      end

      it 'call SendOrderService with formatted data' do
        post '/webhooks/order', params: valid_payload, headers: headers

        expect(SendOrderService).to have_received(:new).with(hash_including(id: '1538830588318-01', customer_name: 'John Doe', items: []))
      end
    end

    context 'without valid token' do
      it 'retorna 401 Unauthorized' do
        post '/webhooks/order', params: valid_payload, headers: {
          'Authorization': 'Bearer wrong'
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when external API fail' do
      let(:error_message) { 'Fetching order error' }

      before do
        allow_any_instance_of(FetchOrderService).to receive(:call).and_raise(error_message)
      end

      it 'returns 502 Bad Gateway' do
        post '/webhooks/order', params: valid_payload, headers: headers

        expect(response).to have_http_status(:bad_gateway)
        expect(SendOrderService).not_to have_received(:new)
      end

      it 'updates the WebhookLog with failure' do
        expect {
          post '/webhooks/order', params: valid_payload, headers: headers
        }.to change(WebhookLog, :count).by(1)

        log = WebhookLog.last
        expect(log.success).to eq(false)
        expect(log.http_status).to eq(502)
        expect(log.error_message).to eq(error_message)
      end
    end

    context 'when the order has already been processed' do
      before do
        WebhookLog.create!(
          order_id: '1538830588318-01',
          account: 'grupoxpto',
          success: true
        )
      end
  
      it 'does not process the order again' do
        expect(FetchOrderService).not_to receive(:new)
        expect(SendOrderService).not_to receive(:new)
  
        post '/webhooks/order', params: valid_payload, headers: headers
  
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the order is in an improper status' do
      before { ActiveJob::Base.queue_adapter = :test }

      it 'schedules a retry and updates the WebhookLog' do
        stub_request(:get, "https://external-service.test/orders/1538830588318-01")
          .to_return(status: 200, body: { id: '1538830588318-01', status: 'payment-approved', customer_name: 'John Doe', items: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

        expect {
          post '/webhooks/order', params: valid_payload, headers: headers
        }.to change(WebhookLog, :count).by(1)

        log = WebhookLog.last
        expect(log.success).to eq(false)
        expect(log.http_status).to eq(202)
        expect(log.error_message).to eq('Status impróprio para processamento.')

        expect(RetryOrderJob).to have_been_enqueued.with('1538830588318-01').at_least(:once)
        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when the order is in the expected status' do
      before do
        ActiveJob::Base.queue_adapter = :test
        allow(FetchOrderService).to receive(:new).and_return(double(call: { id: '1538830588318-01', status: 'ready-for-handling' }))
      end

      it 'processes the order and updates the WebhookLog without scheduling a retry' do
        expect {
          post '/webhooks/order', params: valid_payload, headers: headers
        }.to change(WebhookLog, :count).by(1)

        log = WebhookLog.last
        expect(log.success).to eq(true)
        expect(log.http_status).to eq(200)

        expect(SendOrderService).to have_received(:new)
        expect(RetryOrderJob).not_to have_been_enqueued
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
