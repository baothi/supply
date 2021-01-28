require 'rails_helper'

RSpec.describe 'Visiting the home page', type: :feature do
  before do
    visit root_path
  end

  it 'redirects to login page' do
    expect(page).to have_current_path('/login')
  end
end
