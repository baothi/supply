require 'spree'

namespace :users do
  desc 'Collapse all users with same email address into one user instance'
  task merge_same_email_users: :environment do
    Spree::User.order(updated_at: :desc).group_by(&:email).each do |_email, users|
      next if users.count == 1

      main_user = users.slice!(0)
      users.each do |user_double|
        user_double.team_members.update_all(user_id: main_user.id)
        user_double.destroy
      end

      puts "Merged #{main_user.email}'s accounts into one with the password "\
           "used for #{main_user.shopify_slug}"
    end

    puts 'All Done!'
  end
end
