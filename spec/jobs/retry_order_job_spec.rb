require 'rails_helper'

RSpec.describe RetryOrderJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:order_id) { '1538830588318-01' }

  before do
    allow(FetchOrderService).to receive(:new).and_return(double(call: { status: 'status_improprio' }))
    allow(SendOrderService).to receive(:new).and_return(double(call: true))
  end

  it 'retries the order if status is impróprio' do
    expect {
      RetryOrderJob.perform_now(order_id)
    }.to have_enqueued_job(RetryOrderJob).with(order_id).at_least(:once)
  end

  it 'processes the order if status is esperado' do
    allow(FetchOrderService).to receive(:new).and_return(double(call: { status: 'ready-for-handling' }))

    expect {
      RetryOrderJob.perform_now(order_id)
    }.not_to have_enqueued_job(RetryOrderJob)
    expect(SendOrderService).to have_received(:new)
  end
end
