module ShopifyAuth
  def check_shopify_request
    shopify_request =
      params[:shop].present? && params[:hmac].present? && params[:timestamp].present?

    return unless shopify_request

    verify_shopify_request if
        shopify_request

    # We know we are safe from this point on.
    logout_user_if_necessary

    store = params[:shop]
    user = Spree::User.where(shopify_url: store).first
    raise 'Invalid User' if user.nil?

    raise 'Invalid Slug' if user.shopify_slug.nil?

    sign_in(user)
    redirect_to '/retailer/dashboard'
  end

  def verify_shopify_request
    hmac = params['hmac']

    shopify_params = {
        'code': params['code'],
        'shop': params['shop'],
        'timestamp': params['timestamp']
    }

    # perform hmac validation to determine if the request is coming from Shopify
    h = shopify_params.reject { |k, _| k == 'hmac' }

    # rubocop:disable
    query = URI.escape(h.sort.map { |k, v| "#{k}=#{v}" }.join('&'))
    # rubocop:enable

    digest = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV['SHOPIFY_APP_SECRET_KEY'], query
    )

    raise 'Invalid Shopify Request' unless
        ActiveSupport::SecurityUtils.secure_compare(hmac, digest)
  end
end
