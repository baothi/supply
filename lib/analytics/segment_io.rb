class Analytics::SegmentIo
  attr_reader :user, :client_id, :user_id, :user_email

  def initialize(user, client_id = nil)
    @user = user
    @cliend_id = client_id
    @user_id = -1
    @user_email = user
    # if user.class == User
    #   @user_id = user.id
    #   @user_email = user.email
    # end
  end

  def track(event_type, properties)
    identify
    properties[:application] = 'platform'
    options = {
      user_id: user_id,
      event: event_type,
      properties: properties
    }

    if client_id.present?
      options[:context] = {
          'Google Analytics' => {
            clientId: client_id
          }
        }
    end
    SegmentAnalytics.track(options)
  end

  private

  def identify
    SegmentAnalytics.identify(identify_params)
  end

  def identify_params
    { user_id: user_id, traits: user_traits }
  end

  def user_traits
    {
      email: user_email
    }
  end
end
