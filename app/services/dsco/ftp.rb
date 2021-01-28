module Dsco
  class Ftp
    attr_accessor :sftp
    def initialize
      @sftp = Net::SFTP.start(
        ENV['DSCO_FTP_HOST'],
        ENV['DSCO_FTP_USER'],
        password: ENV['DSCO_FTP_PASSWORD']
      )
    end

    def upload(file, path)
      sftp.upload!(file.path, "in/#{path}")
    end
  end
end
