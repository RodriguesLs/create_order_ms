require 'net/http'
require 'json'

class SendOrderService
  def initialize(order_data)
    @order_data = order_data
  end

  def call
    formatted_data = format_data(@order_data)
    send_to_external_api(formatted_data)
  end

  private

  def format_data(data)
    {
      courier: data.dig(:shippingData, :logisticsInfo, 0, :deliveryCompany),
      status: 'conferir',
      waitingSince: DateTime.parse(data[:creationDate]).to_s,
      shippingLimit: (DateTime.parse(data[:creationDate]) + 1).change(hour: 14, min: 0, sec: 0).iso8601,
      sendStatus: 'no_prazo',
      total: data[:value] / 100.0,
      discounts: data.dig(:totals, 1, :value) / 100.0,
      customerName: data.dig(:clientProfileData, :firstName) + " " + data.dig(:clientProfileData, :lastName),
      customerPhoneNumber: data.dig(:clientProfileData, :phone)&.gsub('+55', ''),
      customerEmail: data.dig(:clientProfileData, :email),
      customerCpfCnpj: data.dig(:clientProfileData, :document),
      customerCep: data.dig(:shippingData, :address, :postalCode)&.gsub('-', ''),
      customerStreet: data.dig(:shippingData, :address, :street),
      customerNumber: data.dig(:shippingData, :address, :number)&.strip,
      customerComplement: data.dig(:shippingData, :address, :complement),
      customerNeighborhood: data.dig(:shippingData, :address, :neighborhood),
      customerCity: data.dig(:shippingData, :address, :city),
      customerUf: data.dig(:shippingData, :address, :state),
      idExternalAPI: data[:orderId],
      freightValue: data.dig(:totals, 2, :value) / 100.0,
      sellerOrderId: data[:sellerOrderId],
      items: data[:items].map do |item|
        {
          description: item[:name],
          ncm: item.dig(:additionalInfo, :ncm),
          codeProduct: item[:productId],
          ean: item[:ean],
          sku: item[:refId],
          comercialUnity: item[:measurementUnit],
          comercialUnityValue: item[:price] / 100.0,
          quantity: item[:quantity]
        }
      end,
      store: data.dig(:sellers, 0, :id)
    }
  end

  def send_to_external_api(formatted_data)
    uri = URI('https://api.externa.com/orders')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = formatted_data.to_json

    response = http.request(request)
    handle_response(response)
  end

  def handle_response(response)
    if response.code.to_i == 200
      puts 'Pedido enviado com sucesso!'
    else
      puts "Erro ao enviar pedido: #{response.body}"
    end
  end
end
