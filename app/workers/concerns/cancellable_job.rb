module CancellableJob
  extend ActiveSupport::Concern
  included do
  end

  class_methods do
    def cancel!(jid)
      Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86400, 1) }
    end
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists("cancelled-#{jid}") }
  end
end
