class AdminUser < ApplicationRecord
  devise :database_authenticatable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def password_required?
    false
  end

  def self.from_omniauth(auth)
    email = auth.info.email
    return new unless email.end_with?('@hingeto.com')

    user = where(email: email).first || new
    user.update_attributes provider: auth.provider,
                           uid:      auth.uid,
                           email:    email
    user.name ||= auth.info.name
    user
  end
end
