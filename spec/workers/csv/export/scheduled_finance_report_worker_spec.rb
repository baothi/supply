require 'rails_helper'

RSpec.describe Csv::Export::ScheduledFinanceReportWorker, type: :worker do
  describe '.execute_after_commit' do
    it 'responds to execute_after_commit class method' do
      expect(described_class).to respond_to(:execute_after_commit)
    end
  end

  describe '#execute_after_commit' do
    it 'responds to execute_after_commit instance method' do
      expect(described_class.new).to respond_to(:execute_after_commit)
    end
  end
end
