require 'net/ssh'
require 'open-uri'
require 'net/sftp'
require 'stringio'
require 'net/ssh/proxy/http'

class SftpService
  def self.within_retailer_sftp
    Net::SFTP.start(ENV['FTP_SERVER'],
                    ENV['FTP_USER_NAME'],
                    password: ENV['FTP_PASSWORD']) do |sftp|
      yield(sftp)
    end
  end

  def self.within_covalent_works_sftp
    Net::SFTP.start(ENV['CW_FTP_SERVER'],
                    ENV['CW_FTP_USER_NAME'],
                    password: ENV['CW_FTP_PASSWORD']) do |sftp|
      yield(sftp)
    end
  end

  # For use with proxy server
  def self.within_revlon_sftp
    quotaguard = URI(ENV['QUOTAGUARDSTATIC_URL'])
    proxy = Net::SSH::Proxy::HTTP.new(
      quotaguard.host, quotaguard.port,
      user: quotaguard.user,
      password: quotaguard.password
    )

    Net::SSH.start(ENV['REVLON_FTP_SERVER'], ENV['REVLON_FTP_USER_NAME'],
                   port: 22,
                   proxy: proxy,
                   password: ENV['REVLON_FTP_PASSWORD']) do |ssh|
      ssh.sftp.connect do |sftp|
        yield(sftp)
      end
    end
  end
end
