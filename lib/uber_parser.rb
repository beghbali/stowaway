require 'ruby-units'

class UberParser < ReceiptParser

  class << self

    def from
      '@uber.com'
    end

    def subject
      "Uber"
    end
  end

  def name
    'Uber'
  end

  def parse
    {
      generated_by:         name,
      billed_to:            to.first,
      ride_requested_at:    match_datetime('request date'),
      pickup_location:      match('pickup location'),
      dropoff_location:     match('dropoff location'),
      payment_card:         match('payment'),
      total_amount:         match_currency('total fare'),
      base_amount:          match_currency('base fare'),
      distance_amount:      match_currency('distance'),
      time_amount:          match_currency('time'),
      surge_amount:         match_currency('surge[\sx\.\d]*'),
      surge_multiple:       match_currency('surge[\sx]+([\.\d]+)'),
      other_amount:         nil, #not implemented
      other_description:    nil, #not implemented
      driver_name:          match('driver'),
      distance:             match_distance('trip statistics\s+distance'),
      duration:             match_duration('duration'),
      average_speed:        match_speed('average speed'),
      map_url:              nil, #not implemented
    }
  end

end