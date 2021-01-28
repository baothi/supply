Spree::Asset.class_eval do
  belongs_to :viewable, polymorphic: true, touch: false
end
