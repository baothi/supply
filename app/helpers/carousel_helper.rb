module CarouselHelper
  def carousel_for(images)
    Carousel.new(self, images).html
  end

  class Carousel
    def initialize(view, images)
      @view = view
      @images = images
    end

    def html
      content = safe_join([indicators, slides, controls])
      content_tag(:div, content, id: uid, class: 'carousel slide')
    end

    private

    attr_accessor :view, :images
    delegate :link_to, :content_tag, :image_tag, :safe_join, to: :view

    def indicators
      items = Array.new(images.count) { |index| indicator_tag(index) }
      content_tag(:ol, safe_join(items), class: 'carousel-indicators carousel-indicators-fall')
    end

    def indicator_tag(index)
      options = {
          class: (index.zero? ? 'active' : ''),
          data: {
              target: "##{uid}",
              slide_to: index
          }
      }

      content_tag(:li, '', options)
    end

    def slides
      items = images.map.with_index { |image, index| slide_tag(image, index.zero?) }
      content_tag(:div, safe_join(items), class: 'carousel-inner')
    end

    def slide_tag(image, is_active)
      options = {
          class: (is_active ? 'carousel-item active' : 'carousel-item')
      }

      content_tag(:div, image_tag(image, class: 'w-full'), options)
    end

    def controls
      safe_join([control_tag('left'), control_tag('right')])
    end

    def control_tag(direction)
      options = {
          class: "#{direction} carousel-control",
          role: 'button',
          data: { slide: direction == 'left' ? 'prev' : 'next' }
      }

      icon = content_tag(:span, '', class: "icon wb-chevron-#{direction}")
      link_to(icon, "##{uid}", options)
    end

    def uid
      @uid ||= SecureRandom.hex(6)
    end
  end
end
