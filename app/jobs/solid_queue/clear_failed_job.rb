module SolidQueue
  class ClearFailedJob < ApplicationJob
    queue_as :service

    def perform
      SolidQueue::FailedExecution
        .where(created_at: ...1.month.ago)
        .find_each(&:discard)
    end
  end
end
