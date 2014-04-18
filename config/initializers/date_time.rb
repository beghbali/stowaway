class DateTime
  def time_of_day
    am = strftime("%P") == 'am'
    if am
      if hour < 5
        'late night'
      elsif hour < 8
        'early morning'
      else
        'morning'
      end
    else
      if hour < 5
        'afternoon'
      elsif hour < 8
        'evening'
      else
        'night'
      end
    end
  end
end