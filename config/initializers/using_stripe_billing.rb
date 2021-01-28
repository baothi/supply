class UsingStripeBilling
  def self.matches?(request)
    !ENV['USE_SHOPIFY_BILLING']
  end
end
