module ActiveAdmin
  module AdminProfiling
    extend ActiveSupport::Concern

    included do
      # before_filter :allow_profiling
    end

    private

    def allow_profiling
      # Rack::MiniProfiler.authorize_request
    end
  end
end
