class AfterCommitWrap
  def initialize
    @callback = Proc.new
  end

  def committed!(*)
    @callback.call
  end

  def before_committed!(*); end

  def rolledback!(*); end

  module Helper
    refine ::Object do
      def after_commit(connection: ActiveRecord::Base.connection)
        connection.add_transaction_record(AfterCommitWrap.new(&Proc.new))
      end
    end
  end
end
