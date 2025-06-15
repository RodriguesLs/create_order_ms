require 'rails_helper'

RSpec.describe WebhookLog, type: :model do
  subject do
    described_class.new(
      order_id: "123456",
      account: "loja_xyz",
      payload: '{"OrderId":"123456","Origin":{"Account":"loja_xyz"}}',
      http_status: 200,
      success: true
    )
  end

  it "is valid with needed attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without order_id" do
    subject.order_id = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without account" do
    subject.account = nil
    expect(subject).to_not be_valid
  end
end
