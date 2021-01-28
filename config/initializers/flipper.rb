require 'flipper/adapters/redis'
module Dropshipper
  def self.flipper
    client = Redis.new
    adapter = Flipper::Adapters::Redis.new(client)
    @flipper ||= Flipper.new(adapter)
  end
end

# Flipper.register(:admins) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
#
# Flipper.register(:hingeto_users) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
#
# Flipper.register(:paid_users) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
#
# # Pricing Plan Based
#
# Flipper.register(:noob) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
#
# Flipper.register(:pro) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
#
# Flipper.register(:expert) do |actor|
#   actor.respond_to?(:admin?) && actor.admin?
# end
