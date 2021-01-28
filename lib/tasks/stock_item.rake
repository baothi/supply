require 'spree'

namespace :stock_item do
  desc 'Set Stock Item Backorderable to true'
  task set_backorderable_to_true: :environment do
    sql = 'UPDATE spree_stock_items SET backorderable = true'
    ActiveRecord::Base.connection.execute(sql)
    Spree::StockLocation.update_all(backorderable_default: true)
    puts 'Done updating backorderable'.green
  end
end
