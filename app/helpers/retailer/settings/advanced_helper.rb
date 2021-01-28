module Retailer::Settings::AdvancedHelper
  def possible_new_owners_map
    non_owner_members.map { |member| [member.user.full_name_for_display, member.id] }
  end

  def non_owner_members
    current_retailer.team_members.reject do |member|
      member.role.name == Spree::Retailer::RETAILER_OWNER
    end
  end
end
