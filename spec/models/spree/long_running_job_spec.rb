require 'rails_helper'

RSpec.describe Spree::LongRunningJob, type: :model do
  subject { build(:spree_long_running_job) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_long_running_job, action_type: nil)).not_to be_valid }
      it { expect(build(:spree_long_running_job, job_type: nil)).not_to be_valid }
      it { expect(build(:spree_long_running_job, status: nil)).not_to be_valid }
      it { expect(build(:spree_long_running_job, initiated_by: nil)).not_to be_valid }
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:action_type) }
    it { is_expected.to validate_presence_of(:job_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:initiated_by) }
    it do
      expect(subject).to validate_inclusion_of(:action_type).
        in_array(Spree::LongRunningJob::ACTION_TYPES)
    end
    it do
      expect(subject).to validate_inclusion_of(:job_type).
        in_array(Spree::LongRunningJob::JOB_TYPES)
    end
    it do
      expect(subject).to validate_inclusion_of(:initiated_by).
        in_array(Spree::LongRunningJob::INITIATED_BY)
    end
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:retailer) }
    it { is_expected.to belong_to(:supplier) }
  end

  describe 'State Machine for Status' do
    context 'begin_job' do
      it { expect(subject).to transition_from(:scheduled).to(:in_progress).on_event(:begin_job) }
    end

    context 'raise_issue' do
      it { expect(subject).to transition_from(:scheduled).to(:error).on_event(:raise_issue) }
      it { expect(subject).to transition_from(:in_progress).to(:error).on_event(:raise_issue) }
      it { expect(subject).to transition_from(:paused).to(:error).on_event(:raise_issue) }
    end

    context 'cancel_job' do
      it { expect(subject).to transition_from(:scheduled).to(:cancelled).on_event(:cancel_job) }
      it { expect(subject).to transition_from(:in_progress).to(:cancelled).on_event(:cancel_job) }
      it { expect(subject).to transition_from(:paused).to(:cancelled).on_event(:cancel_job) }
    end

    context 'pause_job' do
      it { expect(subject).to transition_from(:scheduled).to(:paused).on_event(:pause_job) }
      it { expect(subject).to transition_from(:in_progress).to(:paused).on_event(:pause_job) }
    end

    context 'complete_job' do
      it { expect(subject).to transition_from(:scheduled).to(:completed).on_event(:complete_job) }
      it { expect(subject).to transition_from(:in_progress).to(:completed).on_event(:complete_job) }
      it { expect(subject).to transition_from(:paused).to(:completed).on_event(:complete_job) }
    end
  end

  describe '#initialize_job!' do
    it 'initializes jobs' do
      job = create :spree_long_running_job
      job.initialize_job!
      expect(job.progress).to eq 0
      expect(job.num_of_records_processed).to eq 0
      expect(job.num_of_records_not_processed).to eq 0
      expect(job.time_started).not_to be_nil
      expect(job.time_completed).to be_nil
      expect(job).to be_scheduled
    end
  end

  describe '#initialize_and_begin_job!!' do
    it 'initializes & begins jobs' do
      job = create :spree_long_running_job
      job.initialize_and_begin_job!
      expect(job.progress).to eq 0
      expect(job.num_of_records_processed).to eq 0
      expect(job.num_of_records_not_processed).to eq 0
      expect(job.time_started).not_to be_nil
      expect(job.time_completed).to be_nil
      expect(job).to be_in_progress
    end
  end
end
