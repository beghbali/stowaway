class ReceiptMailer < ActionMailer::Base

  default from: 'support@getstowaway.com'

  def captain_ride_receipt(receipt_id)
    @receipt = Receipt.find(receipt_id)
    mail(to: @receipt.billed_to,
         subject: I18n.t('mailers.receipt_mailer.captain_ride_receipt.subject',
          weekday: @receipt.request.ride.created_at.strftime("%A"),
          timeofday: @receipt.request.ride.created_at.to_datetime.time_of_day,
          savings: "#{number_with_percision(@receipt.savings * 100, percision: 2)}%"))
  end

  def stowaway_ride_receipt(receipt_id)
    @receipt = Receipt.find(receipt_id)
    mail(to: @receipt.billed_to,
         subject: I18n.t('mailers.receipt_mailer.stowaway_ride_receipt.subject',
          weekday: @receipt.request.ride.created_at.strftime("%A"),
          timeofday: @receipt.request.ride.created_at.to_datetime.time_of_day,
          savings: "#{number_with_percision(@receipt.savings * 100, percision: 2)}%"))
  end
end