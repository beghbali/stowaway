require 'ruby-units'

class ReceiptParser < Mail::Message

  class UnknownSenderError < ArgumentError; end

  RECEIPT_SENDERS = {
    UberParser.from => UberParser
  }

  def self.supported_senders
    RECEIPT_SENDERS.keys.flatten
  end

  def self.expected_subjects
    RECEIPT_SENDERS.values.map{|parser| parser.subject}
  end

  def self.parser_for(mail)
    #substring search
    RECEIPT_SENDERS[supported_senders.detect{|sender| mail.from.first.include? sender }]
  end

  def text
    text_part.body.to_s
  end

  def match(what, prefix=nil)
    text.match(/#{what}[:\s]+(#{prefix}[^\n]+)/i) && $1
  end

  def match_date
    text.match(/(#{Date::MONTHNAMES.compact.join('|')})\s+\d{1,2},\s*\d{4}/i) && $&
  end

  def match_time(occurence=1)
    occurences = text.scan(/(\d{1,2}:\d{2}\s*(am|pm))/i)
    occurences[occurence-1] && occurences[occurence-1][0]
  end

  def match_datetime(what)
    match(what).try(:to_datetime)
  end

  def match_currency(what)
    currency = match(what, '\$')
    currency && currency.gsub(/\$/, '').to_f
  end

  def match_distance(what)
    distance = match(what)
    distance && Unit(distance).to_s(:mi).to_f
  end

  def match_duration(what)
    duration = match(what)
    hours, mins, secs = duration && duration.match(/((\d+) hours?[\s,]+)?(\d+) minutes[\s,]+(\d+) seconds/) && [$2.try(:to_i), $3.try(:to_i), $4.try(:to_i)]
    ((hours || 0) * 3600) + ((mins || 0) * 60) + (secs || 0)
  end

  def match_clock(what)
    clock = match(what)
    hours, mins, secs = clock && clock.match(/(\d\d):(\d\d):(\d\d)/) && [$1.try(:to_i), $2.try(:to_i), $3.try(:to_i)]
  end

  def match_speed(what)
    match(what).try(:to_f)
  end
end

