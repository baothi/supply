module Supply
  module ReviewApp
    module Setup
      class Base
        def create_user(teamable)
          user = Spree::User.where(email: teamable.email).first_or_create! do |u|
            u.first_name = 'N/A'
            u.last_name = 'N/A'
            u.shopify_url = teamable.shopify_url
            u.password = ENV['PR_SHOPIFY_STORE_USER_PASSWORD']
          end

          role = teamable.class.name.split('::').last
          owner_role = Spree::Role.find_or_create_by(
            name: "Spree::#{role.camelize}::#{role.upcase}_OWNER".constantize
          )

          team_member = teamable.team_members.first_or_create do |team|
            team.user_id = user.id
            team.role_id = owner_role.id
          end

          user.update(default_team_member_id: team_member.id)
        end

        def create_teamable(team_constant, shop)
          team_constant.find_or_initialize_by(shopify_url: shop) do |team|
            team.email = ENV['PR_SHOPIFY_STORE_SHOP_EMAIL']
            team.address1 = '456 8th Street'
            team.city = 'Oakland'
            team.state = 'CA'
            team.country = 'US'
            team.zipcode = '94607'
            team.phone = ''
            team.plan_name = 'affiliate'
            team.plan_display_name = 'affiliate'
          end
        end

        def create_shopify_credentials(teamable, shop, access_token)
          credential = teamable.shopify_credential || Spree::ShopifyCredential.create(
            teamable: teamable,
            store_url: shop,
            access_token: access_token
          )

          set_up_webhook_creation_job(credential)
        end

        def set_up_webhook_creation_job(credential)
          job = Spree::LongRunningJob.create(
            action_type: 'import',
            job_type: 'shopify_import',
            initiated_by: 'user',
            retailer_id: credential.teamable.id,
            teamable_type: credential.teamable.class.to_s,
            teamable_id: credential.teamable.id
          )
          Shopify::WebhookCreationJob.perform_now(job.internal_identifier)
        end
      end
    end
  end
end
