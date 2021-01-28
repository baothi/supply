class Webhooks::HelloSignController < ActionController::Base
  require 'openssl'

  before_action :verify_request

  def callback
    if @req_body['event']['event_type'] == 'signature_request_all_signed'
      process_signature_complete
    end
    render plain: 'Hello API Event Received', status: 200
  end

  def process_signature_complete
    signature_request_id = @req_body['signature_request']['signature_request_id']
    _agreement_sign = attach_file_to_model(signature_request_id)
    # SupplierMailer.complete_agreement_signature(agreement_sign).deliver_later
  end

  def attach_file_to_model(signature_request_id)
    puts "called attach_file_to_model for: #{signature_request_id}".blue
    # file = HelloSign.signature_request_files(
    #   signature_request_id: signature_request_id,
    #   file_type: 'pdf'
    # )

    # agreement_sign = Spree::SupplierAgreementSignature.
    #                  find_by(signature_request_identifier: signature_request_id)
    #
    # agreement_sign.signature_file = StringIO.new(file)
    # agreement_sign.signature_file_file_name = 'AgreementDocument.pdf'
    # agreement_sign.save
    # agreement_sign
  end

  def verify_request
    @req_body = JSON.parse(params[:json])
    event_time_and_type = @req_body['event']['event_time'] + @req_body['event']['event_type']
    digest = OpenSSL::Digest::Digest.new('sha256')
    calc_hash = OpenSSL::HMAC.hexdigest(digest, ENV['HELLOSIGN_API_KEY'], event_time_and_type)

    head 401 unless calc_hash == @req_body['event']['event_hash']
  end
end
