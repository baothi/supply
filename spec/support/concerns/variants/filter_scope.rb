RSpec.shared_examples 'it respects filter scope for variants' do
  # scopes
  describe 'scopes' do
    before do
      @variants = create_list(:spree_variant, 3, discontinue_on: DateTime.now)
    end

    context 'not_discontinued' do
      it 'selects variants that are not discontinued' do
        variant = Spree::Variant.last
        variant.discontinue_on = nil
        variant.save!

        expect(Spree::Variant.not_discontinued).
          to include(variant)
      end
    end
  end
end
