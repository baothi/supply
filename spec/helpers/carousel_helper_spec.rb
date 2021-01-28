require 'rails_helper'

RSpec.describe CarouselHelper, type: :helper do
  describe '#carousel_for' do
    it 'returns a boostrap carousel markup' do
      images = %w(a.jpg b.jpg)
      carousel_id = 'test-carousel'

      allow_any_instance_of(CarouselHelper::Carousel).to receive(:uid).and_return(carousel_id)

      expected_markup = <<-HTML.strip_heredoc
  <div id="#{carousel_id}" class="carousel slide">
    <ol class="carousel-indicators carousel-indicators-fall">
      <li class="active" data-target="##{carousel_id}" data-slide-to="0"></li>
      <li class="" data-target="##{carousel_id}" data-slide-to="1"></li>
    </ol>

    <div class="carousel-inner"><div class="carousel-item active">
      <img class="w-full" src="/images/a.jpg" alt="A" />
    </div>

    <div class="carousel-item">
      <img class="w-full" src="/images/b.jpg" alt="B" />
    </div>
  </div>
    <a class="left carousel-control" role="button" data-slide="prev" href="##{carousel_id}">
      <span class="icon wb-chevron-left"></span>
    </a>

    <a class="right carousel-control" role="button" data-slide="next" href="##{carousel_id}">
      <span class="icon wb-chevron-right"></span>
    </a>
  </div>
      HTML

      white_space_regex = /\s+/
      rendered_html = helper.carousel_for(images).gsub(white_space_regex, '')
      expected_html = expected_markup.squish.gsub(white_space_regex, '')

      expect(rendered_html).to eq expected_html
    end
  end
end
