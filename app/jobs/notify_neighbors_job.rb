class NotifyNeighborsJob

  @queue = :notifications
  @retry_exceptions = [Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET]

  def self.perform(request_id)
    request = Request.where(id: request_id).first
    unless request.nil?
      proposed_route = request.to_route
      #TODO: add commute time window as we know more about them
      return unless proposed_route.start_locale.present? && proposed_route.end_locale.present?

      Route.similar_to(proposed_route).have_not_been_notified_in(1.day).map do |route|
        relative_day = request.requested_for.to_date.today? ? 'today' : 'tomorrow'
        route.user && (route.user != request.user) &&
        route.user.notify(proposed_route.notification(day: relative_day, time: request.requested_for.in_time_zone('Pacific Time (US & Canada)').to_s(:time))) &&
        route.update(last_notified_at: Time.now)
      end
    end
  end
end