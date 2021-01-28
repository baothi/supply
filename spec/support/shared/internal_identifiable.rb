RSpec.shared_examples 'an internal_identifiable model' do
  describe '#before_validate' do
    it 'generates an internal_identifier before saving'  do
      subject.internal_identifier = nil
      subject.save!
      expect(subject).to be_valid # Because II is now generated
      expect(subject.internal_identifier).not_to be_nil
    end
  end
end
