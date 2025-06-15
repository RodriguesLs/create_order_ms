require 'rails_helper'
require 'webmock/rspec'

RSpec.describe SendOrderService, type: :service do
  let(:order_data) { JSON.parse(File.read(Rails.root.join('spec/support/payloads/order_input.json')), symbolize_names: true) }
  let(:formatted_data) { JSON.parse(File.read(Rails.root.join('spec/support/payloads/order_output.json')), symbolize_names: true) }

  let(:service) { SendOrderService.new(order_data) }

  describe '#call' do
    context 'when the external API responds successfully' do
      before do
        stub_request(:post, "https://api.externa.com/orders")
          .with(body: formatted_data, headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '', headers: {})
      end

      it 'formats the data correctly' do
        expect(service.send(:format_data, order_data)).to eq(formatted_data)
      end

      it 'sends the data to the external API' do
        service.call

        expect(WebMock).to have_requested(:post, "https://api.externa.com/orders")
          .with(body: formatted_data, headers: { 'Content-Type' => 'application/json' })
      end
    end

    context 'when the external API responds with an error' do
      before do
        stub_request(:post, "https://api.externa.com/orders")
          .to_return(status: 500, body: 'Internal Server Error', headers: {})
      end

      it 'logs the error message' do
        expect { service.call }.to output(/Erro ao enviar pedido: Internal Server Error/).to_stdout
      end
    end
  end
end