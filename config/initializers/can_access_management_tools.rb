class CanAccessManagementTools
  def self.matches?(request)
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:hingeto_user?) && current_user.hingeto_user?
  end
end
