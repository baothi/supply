class AddRiskRecommendationToSpreeOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :risk_recommendation, :string
  end
end
