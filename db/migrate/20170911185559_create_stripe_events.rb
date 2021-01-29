class CreateStripeEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_events do |t|
      t.string :internal_identifier
      t.string :event_identifier
      t.datetime :event_created
      t.references :stripe_eventable, polymorphic: true, index: { name: 'index_on_type_and_id' }
      t.jsonb :event_object

      t.timestamps
    end
  end
end
