Spree::User.class_eval do
  has_many :long_running_jobs
  has_many :team_members

  # validates :last_name, presence: true
  # validates :first_name, presence: true
  validates :email, uniqueness: { scope: :shopify_url }

  before_save :set_shopify_slug

  delegate :teamable, to: :team_member

  def default_team_member
    team_members.find_by(id: default_team_member_id) || team_members.last
  end

  alias_method :team_member, :default_team_member

  def role
    team_member.role
  end

  def email_changed?
    false
  end

  def set_shopify_slug
    self.shopify_slug = self.shopify_url.split('.myshopify.com')[0] if
        self.shopify_slug.nil? && self.shopify_url.present?
  end

  def full_name(last_name_first = false)
    return "#{last_name}, #{first_name}".strip if last_name_first

    "#{first_name} #{last_name}".strip
  end

  def send_reset_password_instructions(option = {})
    token = set_reset_password_token
    send_reset_password_instructions_notification(token, option)

    token
  end

  def send_reset_password_instructions_notification(token, options)
    ::UserMailer.reset_password_instructions(self, token, options).deliver_later
  end

  def self.send_reset_password_instructions(attributes = {}, mailer_params = {})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    recoverable.send_reset_password_instructions(mailer_params) if recoverable.persisted?
    recoverable
  end

  def regenerate_confirmation_token!
    self.generate_confirmation_token!
    token = self.confirmation_token
    token
  end

  def send_confirmation_instructions(option = {})
    self.generate_confirmation_token!
    token = self.confirmation_token
    send_confirmation_instructions_notification(token, option)

    token
  end

  def send_confirmation_instructions_notification(token, option)
    ::UserMailer.confirmation_instructions(self, token, option).deliver_later
  end

  def self.reset_password_keys
    %i(email)
  end

  def retailer_user?
    team_member.teamable.is_a? Spree::Retailer
  end

  def supplier_user?
    team_member.teamable.is_a? Spree::Supplier
  end

  def supplier_owner_or_admin?
    role.name == Spree::Supplier::SUPPLIER_OWNER || role.name == Spree::Supplier::SUPPLIER_ADMIN
  end

  def retailer_owner?
    role.name == Spree::Retailer::RETAILER_OWNER
  end

  def retailer_owner_or_admin?
    retailer_owner? || role.name == Spree::Retailer::RETAILER_ADMIN
  end

  def hingeto_user?
    email.include?('hingeto.com')
  end

  def full_name_for_display
    return self.email if self.first_name.nil? || self.last_name.nil?
    return self.email if self.first_name == 'N/A' || self.last_name == 'N/A'

    "#{self.first_name} #{self.last_name}"
  end

  protected

  # Devise: Allowing Unconfirmed Access
  def confirmation_required?
    # use self.confirmed_at to enable user access for specified period.
    false
  end
end
