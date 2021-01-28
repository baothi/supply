# This service aims to download all relevant events.
# The ProcessEventService aims to act appropriately
module ShopifyCache
  class EventService
    # team: the supplier or retailer object
    #
    # params: custom shopify finder params e.g. {"updated_at_min": DateTime.now - 1.day}.to_json
    #
    # filter: Order, Product
    #
    # verb: Visit https://help.shopify.com/en/api/reference/events/event
    # for list of valid verbs per entity type

    attr_accessor :custom_params, :role, :shopify_url, :team,
                  :subject_type, :verb

    def initialize(team:, filter:, verb:, params: '{}')
      raise 'Team Type required' if team.blank?
      # Filter: product
      raise 'filter required' if filter.blank?
      raise 'Only works with filter:Product for now' unless filter.casecmp('product').zero?
      raise 'Only works with verb:destroy, for now' unless verb.casecmp('destroy').zero?
      # verb: destroy
      raise 'Verb required' if verb.blank?

      # Assign variables
      @team = team
      @subject_type = subject_type
      @verb = verb
      @role = @team.team_type
      @shopify_url = team.shopify_url
      # Custom Parameters
      @custom_params = JSON.parse(params)
      custom_params['filter'] = filter
      custom_params['verb'] = verb
    end

    def perform
      begin
        @team.init # Initialize Shopify Session


        # Find all the events
        shopify_events = ShopifyAPIRetry.retry do
          ShopifyAPI::Event.all(
            params: {
                limit: PER_PAGE.to_i
            }.merge(custom_params)
          )
        end
        process_events(shopify_events)

        while shopify_events.next_page?
          shopify_events = shopify_events.fetch_next_page
          process_events(shopify_events)
        end

        @team.last_synced_shopify_events_at = DateTime.now
        @team.save!

        # After Saving them all, now process
        ShopifyCache::ProcessEventService.new(team: team).perform
      rescue => ex
        ErrorService.new(exception: ex).perform
      end
    end

    private

    PER_PAGE = 250.0

    def process_events(shopify_events)
      # Insert into MongoDB
      shopify_events.map! do |shopify_event|
        shopify_event = shopify_event.attributes
        shopify_event[:shopify_url] = shopify_url
        shopify_event[:role] = role
        shopify_event
      end

      # Upsert the Event
      shopify_events.as_json.each do |shopify_event|
        ShopifyCache::Event.new(shopify_event).upsert
      end
    end
  end
end
