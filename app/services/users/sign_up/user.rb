module Users
  module SignUp
    class User
      attr_accessor :business_name, :website, :facebook_url, :instagram_url, :ecommerce_platform,
                    :email, :password, :password_confirmation, :phone_number,
                    :user, :supplier, :retailer, :type, :user_id

      include ActiveModel::Model

      def initialize(params = {})
        super(params)
        @user = set_user(params)
        @supplier = set_supplier(params)
        @retailer = set_retailer(params)
      end

      def save_user
        if existing_user?
          user.errors.add(:base, 'This email address is in use')
          return false
        end
        return false unless user.valid?

        user.save
      end

      def existing_user?
        Spree::User.find_by_email(user.email).present?
      end

      def save
        return save_retailer if type == 'retailer'
        return save_supplier if type == 'supplier'

        false
      end

      def save_retailer
        return false unless retailer.valid?

        retailer.save

        retailer.team_members.create(user_id: user.id, role_id: get_owner_role.id)
      end

      def save_supplier
        return false unless supplier.valid?

        supplier.save

        supplier.team_members.create(user_id: user.id, role_id: get_owner_role.id)
      end

      def get_owner_role
        Spree::Role.find_or_create_by(
          name: "Spree::#{type.capitalize}::#{type.upcase}_OWNER".constantize
        )
      end

      def errors
        errors = []
        errors << user.errors.full_messages if user&.errors
        errors << supplier.errors.full_messages if supplier&.errors
        errors << retailer.errors.full_messages if retailer&.errors
        errors.join('<br> – ')
      end

      private

      def set_user(params)
        return Spree::User.find(params[:user_id]) if params[:user_id].present?

        user = Spree::User.find_or_initialize_by(email: params[:email])
        user.assign_attributes(
          params.slice(:email, :password, :password_confirmation)
        )
        user
      end

      def set_supplier(params)
        return nil unless params[:type] == 'supplier'

        Spree::Supplier.new(
          name: params[:business_name],
          email: user.email,
          ecommerce_platform: params[:ecommerce_platform],
          phone_number: params[:phone_number],
          website: params[:website],
          facebook_url: params[:facebook_url],
          instagram_url: params[:instagram_url]
        )
      end

      def set_retailer(params)
        return nil unless params[:type] == 'retailer'

        Spree::Retailer.new(
          name: params[:business_name],
          email: user.email,
          ecommerce_platform: params[:ecommerce_platform],
          phone_number: params[:phone_number],
          website: params[:website],
          facebook_url: params[:facebook_url],
          instagram_url: params[:instagram_url]
        )
      end
    end
  end
end
