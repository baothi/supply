require 'spree'

namespace :heroku do
  task pr_predestroy: :environment do
    Supply::ReviewApp::Teardown::Base.new.run
  end

  task setup: :environment do
    Supply::ReviewApp::Setup::Supplier.new.run
    Supply::ReviewApp::Setup::Retailer.new.run
  end
end
