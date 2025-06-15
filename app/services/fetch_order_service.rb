require 'net/http'
require 'uri'
require 'json'

class FetchOrderService
  BASE_URL = ENV.fetch("ORDER_API_URL") { "https://external-service.test" }

  def initialize(order_id)
    @order_id = order_id
  end

  def call
    uri = URI.parse("#{BASE_URL}/orders/#{@order_id}")
    response = Net::HTTP.get_response(uri)

    raise "Erro ao buscar pedido: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body, symbolize_names: true)
  end
end
