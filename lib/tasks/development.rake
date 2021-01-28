require 'spree'
namespace :development do
  # To reset environment
  # rake development:reset_data
  # rake development:sample_data
  #
  desc 'Used to completely reset the environment'
  task reset_env: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('cannot_run_in_production').red
      next
    end

    Rake::Task['development:reset_data'].invoke
    Rake::Task['development:sample_data'].invoke
  end
  
  desc 'Used to drop database & recreate. Only works in development'
  task reset_data: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('cannot_run_in_production').red
      next
    end

    puts 'Drop and recreate database? (This cannot be undone!) y[es] or n[o]'.blue

    input = Dropshipper::CommandLineHelper.get_input

    if input == 'y'
      #  db:environment:set RAILS_ENV=development
      Rake::Task['db:drop:all'].invoke
      Rake::Task['db:create:all'].invoke
      Rake::Task['db:schema:load'].invoke
      # Rake::Task['db:migrate'].invoke
      reset_all_columns! # Done to avoid weird column missing issues.
      Rake::Task['db:seed'].invoke
      puts I18n.t('successfully_dropped_and_recreated_tables').green
    else
      puts I18n.t('database_left_intact').yellow
    end
  end

  desc 'Used to import sample data. Only works in development'
  task sample_data: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('cannot_run_in_production').red
      next
    end

    puts 'Import sample_data? y[es] or n[o]'.blue
    input = Dropshipper::CommandLineHelper.get_input

    if input == 'y'
      Rake::Task['spree_sample:load'].invoke
      Rake::Task['sample_data:load_additional'].invoke
      Rake::Task['sample_data:associate_data'].invoke
      Rake::Task['development:assign_admins'].invoke
      puts I18n.t('successfully_loaded_data').green
    else
      puts I18n.t('no_data_imported').yellow
    end
  end

  def reset_all_columns!
    ApplicationRecord.descendants.each do |model|
      puts "Resetting: #{model} Table".yellow
      model.reset_column_information
    end
    puts 'Completed Models Reset'.green
  end

  desc 'Used to make every user an admin so that can use Spree Backend.'
  task assign_admins: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('cannot_run_in_production').red
      next
    end

    puts 'Proceed with admin converstion y[es] or n[o]'.blue
    input = Dropshipper::CommandLineHelper.get_input

    if input == 'y'
      Spree::User.all.each do |user|
        admin_role = Spree::Role.where(name: 'admin').first # Assumption

        Spree::RoleUser.where(
          role_id: admin_role.id,
          user_id: user.id
        ).first_or_create! do |_role_user|
        end
      end
      puts I18n.t('successfully_loaded_data').green
    else
      puts I18n.t('no_data_imported').yellow
    end
  end
end
