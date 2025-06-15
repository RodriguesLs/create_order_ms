require 'rails_helper'
require 'webmock/rspec'

RSpec.describe FetchOrderService do
  let(:order_id) { '1538830588318-01' }
  let(:expected_response) do
    {
      id: order_id,
      customer: {
        name: 'João da Silva'
      },
      total: 150.00
    }
  end

  before do
    stub_request(:get, "https://external-service.test/orders/#{order_id}")
      .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  context "when success" do
    it "retorna os dados do pedido como um hash" do
      result = described_class.new(order_id).call

      expect(result).to be_a(Hash)
      expect(result[:id]).to eq(order_id)
      expect(result[:customer][:name]).to eq('João da Silva')
    end
  end

  context "when failed" do
    before do
      stub_request(:get, "https://external-service.test/orders/#{order_id}")
        .to_return(status: 500, body: "Erro interno")
    end

    it "lança um erro informativo" do
      expect {
        described_class.new(order_id).call
      }.to raise_error(RuntimeError, /Erro ao buscar pedido/)
    end
  end
end
