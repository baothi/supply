RSpec.shared_examples 'a merchandise workflow' do
  describe 'Events' do
    context 'initial state' do
      it 'has initial state of pending_review_by_hingeto' do
        expect(subject.aasm_state).to eq 'not_submitted'
      end
    end

    context 'hingeto_start_review' do
      it 'changes state from not_submitted to in review by hingeto' do
        expect { subject.hingeto_start_review }.to change(subject, :aasm_state).
          from('not_submitted').to('in_review_by_hingeto')
      end
      it 'changes state from pending review by hingeto to in review by hingeto' do
        subject.aasm_state = 'pending_review_by_hingeto'
        expect { subject.hingeto_start_review }.to change(subject, :aasm_state).
          from('pending_review_by_hingeto').to('in_review_by_hingeto')
      end
    end

    context 'hingeto_reject' do
      before do
        subject.hingeto_start_review
      end

      it 'changes state from in_review_by_hingeto to declined_by_hingeto' do
        expect { subject.hingeto_reject }.to change(subject, :aasm_state).
          from('in_review_by_hingeto').to('declined_by_hingeto')
      end
    end

    context 'hingeto_approve' do
      before do
        subject.hingeto_start_review
      end

      it 'changes state from in_review_by_hingeto to pending_review_by_retailer' do
        expect { subject.hingeto_approve }.to change(subject, :aasm_state).
          from('in_review_by_hingeto').to('pending_review_by_retailer')
      end
    end

    context 'retailer_start_review' do
      before do
        subject.aasm_state = 'pending_review_by_retailer'
      end

      it 'changes state from pending_review_by_retailer to in_review_by_retailer' do
        expect { subject.retailer_start_review }.to change(subject, :aasm_state).
          from('pending_review_by_retailer').to('in_review_by_retailer')
      end
    end

    context 'retailer_reject' do
      before do
        subject.aasm_state = 'in_review_by_retailer'
      end

      it 'changes state from in_review_by_retailer to declined_by_retailer' do
        expect { subject.retailer_reject }.to change(subject, :aasm_state).
          from('in_review_by_retailer').to('declined_by_retailer')
      end
    end

    context 'retailer_approve' do
      before do
        subject.aasm_state = 'in_review_by_retailer'
      end

      it 'changes state from in_review_by_retailer to approved_by_retailer' do
        expect { subject.retailer_approve }.to change(subject, :aasm_state).
          from('in_review_by_retailer').to('approved_by_retailer')
      end
    end

    context 'hingeto_request_additional_information' do
      before do
        subject.aasm_state = 'in_review_by_hingeto'
      end

      it 'changes state from in_review_by_hingeto to hingeto_requires_additional_information' do
        expect { subject.hingeto_request_additional_information }.to change(subject, :aasm_state).
          from('in_review_by_hingeto').to('hingeto_requires_additional_information')
      end
    end

    context 'retailer_request_additional_information' do
      before do
        subject.aasm_state = 'in_review_by_retailer'
      end

      it 'changes state from in_review_by_retailer to retailer_requires_additional_information' do
        expect { subject.retailer_request_additional_information }.to change(subject, :aasm_state).
          from('in_review_by_retailer').to('retailer_requires_additional_information')
      end
    end
    # context 'whiny_persistence' do
    #   before do
    #     subject.save
    #     # setting invalid data for instagram url
    #     subject.update_columns(instagram_url: 'www.instagram.com/a')
    #   end
    #   it 'raises exception when base application has validation issues' do
    #     expect { subject.hingeto_start_review! }.to raise_error(ActiveRecord::RecordInvalid)
    #   end
    # end
  end

  describe '#submit_for_approval!' do
    it 'creates one variant version & one variant listing version' do
    end
  end
end
