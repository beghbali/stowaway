class NotifyNeighborsJob

  @queue = :notify_neighbor

  def self.perform(request_id)
    request = Request.find(request_id)
    unless request.nil?
      proposed_route = request.to_route
      #TODO: add commute time window as we know more about them
      Route.similar_to(proposed_route).have_not_been_notified_in(1.day).map do |route|
        relative_time = request.requested_for.to_date.today? ? 'today' : 'tomorrow'
        route.user.notify(proposed_route.notification(time: relative_time))
      end
    end
  end
end