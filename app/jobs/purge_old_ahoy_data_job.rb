class PurgeOldAhoyDataJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 90.days.ago
    Ahoy::Event.joins(:visit).where("ahoy_visits.started_at < ?", cutoff).delete_all
    Ahoy::Visit.where("started_at < ?", cutoff).delete_all
  end
end
