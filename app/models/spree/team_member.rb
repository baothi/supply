module Spree
  class TeamMember < ApplicationRecord
    include InternalIdentifiable

    # acts_as_messageable

    belongs_to :teamable, polymorphic: true
    belongs_to :user
    belongs_to :role

    validates :teamable, presence: true
    validates :user, presence: true
    validates :role, presence: true

    def also_member_of_supplier?(supplier)
      membership = Spree::TeamMember.find_by(user_id: user.id,
                                             teamable_type: 'Spree::Supplier',
                                             teamable_id: supplier.id)
      membership
    end

    def also_member_of_retailer?(retailer)
      membership = Spree::TeamMember.find_by(user_id: user.id,
                                             teamable_type: 'Spree::Retailer',
                                             teamable_id: retailer.id)
      membership
    end

    def transfer_ownership_to(member)
      errors[:base] << 'User does not exist in your team' and return if member.nil?
      ApplicationRecord.transaction do
        member.update(role: Spree::Role.find_by(name: Spree::Retailer::RETAILER_OWNER))
        self.update(role: Spree::Role.find_by(name: Spree::Retailer::RETAILER_ADMIN))
      end
    end

    # def mailboxer_name
    #   "#{user.full_name} (#{role.name.humanize.titleize}, #{teamable.name})"
    # end
    #
    # def mailboxer_email(_object = nil)
    #   user.email
    # end
  end
end
