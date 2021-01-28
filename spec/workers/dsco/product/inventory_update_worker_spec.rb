require 'rails_helper'

RSpec.describe Dsco::Product::InventoryUpdateWorker, type: :worker do
  let!(:variant_one) { create(:spree_variant_with_quantity, dsco_identifier: '12345', quantity: 1) }
  let!(:variant_two) { create(:spree_variant_with_quantity, dsco_identifier: '67890', quantity: 4) }
  let(:job) { create(:spree_long_running_job) }
  let(:hsh) do
    [
      { 'dsco_item_id' => '12345', 'quantity_available' => 20 },
      { 'dsco_item_id' => '67890', 'quantity_available' => 30 }
    ]
  end

  before do
    allow_any_instance_of(ImportableJob).to receive(:extract_data_from_job_file).
      with(job).and_return(hsh)
  end

  describe 'perform' do
    subject { described_class.new }

    it 'updates inventory' do
      expect(variant_one.reload.count_on_hand).to eq 1
      expect(variant_two.reload.count_on_hand).to eq 4

      subject.perform(job.internal_identifier)

      expect(variant_one.reload.count_on_hand).to eq 20
      expect(variant_two.reload.count_on_hand).to eq 30
    end
  end
end
