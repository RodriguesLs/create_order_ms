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
        Account: 'grupooscar'
      }
    }.to_json
  end

  describe 'POST /webhooks/order' do
    context 'with valid token' do
      it 'returns 200 OK' do
        post '/webhooks/order', params: valid_payload, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'cria um WebhookLog com os dados recebidos' do
        expect {
          post '/webhooks/order', params: valid_payload, headers: headers
        }.to change(WebhookLog, :count).by(1)

        log = WebhookLog.last
        expect(log.order_id).to eq("1538830588318-01")
        expect(log.account).to eq("grupooscar")
        expect(log.success).to eq(true) # ajustar conforme o comportamento do serviço externo
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
  end
end
