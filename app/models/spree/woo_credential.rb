class Spree::WooCredential < ApplicationRecord

  # The owner of the credential
  belongs_to :teamable, polymorphic: true

  validates_presence_of :store_url,:consumer_key,:consumer_secret,:teamable_type,:teamable_id,:version, :on => :update

  def retailer?
    teamable.class.to_s == 'Spree::Retailer'
  end

  private

    def supplier?
      teamable.class.to_s == 'Spree::Supplier'
    end
end
