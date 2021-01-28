# This service aims to process all relevant events.
module ShopifyCache
  class ProcessEventService
    # team: the supplier or retailer object. For now, we are only going to handle for suppliers

    attr_accessor :shopify_url, :team

    def initialize(team:)
      raise 'Team required' if team.nil? || team.shopify_url.nil?

      @team = team
      @shopify_url = team.shopify_url
    end

    def perform
      begin
        ShopifyCache::Event.unprocessed.where(shopify_url: @shopify_url).all.each do |shopify_event|
          result = process_event(shopify_event)
          shopify_event.mark_as_processed! if result
        end

        @team.last_processed_shopify_events_at = DateTime.now
        @team.save!
      rescue => ex
        ErrorService.new(exception: ex).perform
      end
    end

    private

    def process_event(shopify_event)
      return unless shopify_event.subject_type.casecmp('product').zero?

      verb = shopify_event.verb
      case verb
      when 'destroy'
        ShopifyCache::Product.find(shopify_event.subject_id)&.mark_as_deleted!
        return true
      else
        puts "Invalid Event Found: #{verb}".yellow
        return false
      end
    end
  end
end
