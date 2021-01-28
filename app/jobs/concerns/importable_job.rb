module ImportableJob
  extend ActiveSupport::Concern

  def extract_data_from_job_file(job)
    begin
      file = get_file_content(job)
      data = CSV.parse(file, headers: true)
      data.map(&:to_hash)
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      nil
    end
  end

  def get_file_content(job)
    url = if Rails.env.development?
            "#{Rails.root}/public#{job.input_csv_file.url(:original, timestamp: false)}"
          else
            job.input_csv_file.url
          end
    tmpfile = Tempfile.new(job.input_csv_file_file_name)
    tmpfile.binmode

    open(url) do |url_file|
      tmpfile.write(url_file.read)
    end
    tmpfile.rewind
    tmpfile.read
  end
end
