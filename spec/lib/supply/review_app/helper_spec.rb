require 'rails_helper'

RSpec.describe Supply::ReviewApp::Helpers, type: :helper do
  let(:pr_name) { 'app-pr-1' }
  let(:parent_app_name) { 'app' }

  describe '.review_app?' do
    context "when 'app_name' is 'app-pr-1'" do
      before { allow(Supply::ReviewApp::Helpers).to receive(:app_name) { pr_name } }

      it 'returns truthy' do
        expect(Supply::ReviewApp::Helpers).to be_review_app
      end
    end

    context "when 'app_name' is nil" do
      before { allow(Supply::ReviewApp::Helpers).to receive(:app_name).and_return(nil) }

      it 'returns falsey' do
        expect(Supply::ReviewApp::Helpers).not_to be_review_app
      end
    end
  end

  describe '.app_name' do
    it "returns what is set on 'ENV['HEROKU_APP_NAME']'" do
      ENV['HEROKU_APP_NAME'] = pr_name
      expect(Supply::ReviewApp::Helpers.app_name).to eql pr_name
    end
  end

  describe '.parent_app_name' do
    it "returns what is set on 'ENV['HEROKU_PARENT_APP_NAME']'" do
      ENV['HEROKU_PARENT_APP_NAME'] = parent_app_name
      expect(Supply::ReviewApp::Helpers.parent_app_name).to eql parent_app_name
    end
  end

  describe '.app_number' do
    context 'when real PR name is set' do
      it "returns the number in 'ENV['HEROKU_APP_NAME']'" do
        ENV['HEROKU_APP_NAME'] = pr_name
        expect(Supply::ReviewApp::Helpers.app_number).to eql 'PR-1'
      end
    end

    context 'when PR name is nil' do
      it 'returns nil' do
        ENV['HEROKU_APP_NAME'] = nil
        expect(Supply::ReviewApp::Helpers.app_number).to be_nil
      end
    end

    context 'when PR name is invalid' do
      it 'returns nil' do
        ENV['HEROKU_APP_NAME'] = 'invalid-review-app-name-without-digit'
        expect(Supply::ReviewApp::Helpers.app_number).to be_nil
      end
    end
  end
end
