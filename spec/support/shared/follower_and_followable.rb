RSpec.shared_examples 'a follower model' do
  describe 'added methods' do
    it 'responds to the methods added by the "act_as_followable" gem'  do
      expect(subject).to respond_to(
        :follow, :stop_following, :following?, :follow_count, :all_follows,
        :all_following, :follows_by_type, :following_by_type, :follows_scoped
      )
    end
  end
end

RSpec.shared_examples 'a followable model' do
  describe 'added methods' do
    it 'responds to the methods added by the "act_as_followable" gem'  do
      expect(subject).to respond_to(
        :followers, :followers_scoped, :followers_count, :followers_by_type,
        :followers_by_type_count, :followed_by?, :block, :unblock, :blocks, :blocked_followers_count
      )
    end
  end
end
