class Spree::SupplierReferral < ApplicationRecord
  belongs_to :spree_retailer

  validates :url,
            presence: true,
            http_url: true,
            uniqueness: { scope: :spree_retailer_id,
                          message: 'already exists in your invites.' }

  def self.top_retailers_with_highest_referrals
    count_hash = Spree::SupplierReferral.
                 group(:spree_retailer_id).
                 order('count(*) desc').
                 limit(5).count

    count_hash.map do |id, count|
      { retailer: Spree::Retailer.find(id), count: count }
    end
  end
end
