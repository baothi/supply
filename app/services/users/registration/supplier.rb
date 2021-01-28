module Users
  module Registration
    class Supplier
      attr_accessor :business_name, :first_name, :last_name, :email, :password,
                    :password_confirmation, :user, :supplier

      include ActiveModel::Model

      def initialize(params = {})
        super(params)
        @user = set_user(params)
        @supplier = set_supplier(params)
      end

      def execute
        return false unless all_valid?

        user.save
        supplier.save

        supplier.team_members.create(user_id: user.id, role_id: get_owner_role.id)
      end

      def get_owner_role
        Spree::Role.find_or_create_by(name: Spree::Supplier::SUPPLIER_OWNER)
      end

      def errors
        (user.errors.full_messages + supplier.errors.full_messages).join('<br> – ')
      end

      def all_valid?
        supplier_valid = supplier.valid?
        user_valid = user.valid?
        supplier_valid && user_valid
      end

      def set_user(params)
        user = Spree::User.find_or_initialize_by(email: params[:email])
        user.assign_attributes(
          params.slice(:email, :first_name, :last_name, :password, :password_confirmation)
        )
        user
      end

      def set_supplier(params)
        Spree::Supplier.new(name: params[:business_name], email: params[:email])
      end
    end
  end
end
