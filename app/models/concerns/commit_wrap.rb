module CommitWrap
  extend ActiveSupport::Concern

  class_methods do
    def execute_after_commit(connection: ActiveRecord::Base.connection)
      connection.add_transaction_record(AfterCommitWrap.new(&Proc.new))
    end
  end

  def execute_after_commit(connection: ActiveRecord::Base.connection)
    connection.add_transaction_record(AfterCommitWrap.new(&Proc.new))
  end
end
