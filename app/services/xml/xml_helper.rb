module Xml::XmlHelper
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def parse_text_for_element(el, node_name)
    node = el.at_css(node_name)
    return node.text if node.present?
  end

  def find_element_by_name(elements, name)
    val = elements.at_css("[name='#{name}']")
    return val.text if val.present?
  end
end
