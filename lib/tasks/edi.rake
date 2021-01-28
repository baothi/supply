#######
# EDI #
#######
require 'spree'
namespace :edi do
  desc 'Ensure EDI Orders are remitted'
  task remit_orders: :environment do
    puts 'remit_edi_orders'.green
    # All recent orders
    orders = Spree::Order.locate_orders_not_yet_sent_via_edi(DateTime.now - 2.hours)
    orders.each do |order|
      begin
        CovalentWorks::Outbound::PurchaseOrderService.new(order: order).perform unless
            order.shipment_state == 'canceled' || order.shipment_state == 'shipped' ||
            order.all_line_items_are_out_of_stock?
        sleep 1 # Mitigate FTP issues
      rescue => ex
        puts "Issue: #{ex}".red
        Rollbar.error(ex, order: order.id)
      end
    end
    puts 'done'.green
  end

  desc 'Ingest ASN from Revlon'
  task ingest_revlon_asns: :environment do
    puts 'ingesting asns for Revlon suppliers'.green
    # Todo: change directory path, backup mechanism according to Revlon requirements

    return unless ENV['RAILS_ENV'] == 'production'

    SftpService.within_revlon_sftp do |sftp|
      path = '/Out'
      sftp.dir.glob(path, '*.csv') do |entry|
        puts entry.name
        file_name = "#{path}/#{entry.name}"

        # Download file
        csv_content = sftp.download!(file_name)

        Revlon::Inbound::FulfillmentService.new(csv_content: csv_content).perform

        # Now backup
        # archive_file_name = "#{path}/Archive/#{Time.now.to_i}-#{entry.name}"
        # sftp.file.open(archive_file_name, 'w') do |f|
        #   f.puts "#{content}\n"
        # end

        # sftp.remove(file_name)
      end
      puts 'completed!'.green
    end

    puts 'done'.green
  end

  desc 'Ingest ASN from Covalent'
  task ingest_asns: :environment do
    puts 'ingest_asns'.green

    return unless ENV['RAILS_ENV'] == 'production'

    Net::SFTP.start(ENV['CW_FTP_SERVER'],
                    ENV['CW_FTP_USER_NAME'],
                    password: ENV['CW_FTP_PASSWORD']) do |sftp|
      path = '/Inbox/856'
      sftp.dir.glob(path, '*.xml') do |entry|
        # puts entry.name
        file_name = "#{path}/#{entry.name}"

        # Download file
        content = sftp.download!(file_name)
        # Now download each Auth Response & Process now
        # puts "#{data}".yellow

        CovalentWorks::Inbound::FulfillmentService.new(
          content: content
        ).perform

        # Now backup
        archive_file_name = "#{path}/Archive/#{Time.now.to_i}-#{entry.name}"
        sftp.file.open(archive_file_name, 'w') do |f|
          f.puts "#{content}\n"
        end

        # OperationsMailer.generic_email(retail_connection,
        #                                subject,
        #                                body).deliver_now!
        sftp.remove(file_name)
      end
    end

    puts 'done'.green
  end

  desc 'Ingest Inventories from Covalent'
  task ingest_inventories: :environment do
    puts 'ingest_asns'.green

    return unless ENV['RAILS_ENV'] == 'production'

    Net::SFTP.start(ENV['CW_FTP_SERVER'],
                    ENV['CW_FTP_USER_NAME'],
                    password: ENV['CW_FTP_PASSWORD']) do |sftp|
      path = '/Inbox/846'
      sftp.dir.glob(path, '*.xml') do |entry|
        # puts entry.name
        file_name = "#{path}/#{entry.name}"

        # Download file
        content = sftp.download!(file_name)
        # Now download each Auth Response & Process now
        # puts "#{data}".yellow

        CovalentWorks::Inbound::InventoryService.new(
          content: content
        ).perform

        # Now backup
        archive_file_name = "#{path}/Archive/#{Time.now.to_i}-#{entry.name}"
        sftp.file.open(archive_file_name, 'w') do |f|
          f.puts "#{content}\n"
        end

        # OperationsMailer.generic_email(retail_connection,
        #                                subject,
        #                                body).deliver_now!
        sftp.remove(file_name)
      end
    end
  end
end
