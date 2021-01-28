RSpec.shared_examples 'a mini_identifiable model' do
  describe '#before_validate' do
    it 'generates an mini_identifier before saving'  do
      subject.mini_identifier = nil
      subject.save!
      expect(subject).to be_valid
      expect(subject.mini_identifier).not_to be_nil
    end
  end
end
