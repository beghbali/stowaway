class ReceiptMailer < ActionMailer::Base
  include ActionView::Helpers::NumberHelper

  default from: 'Stowaway <support@getstowaway.com>'

  def captain_ride_receipt(receipt_id)
    @receipt = Receipt.find(receipt_id)
    mail(to: @receipt.billed_to,
         subject: I18n.t('mailers.receipt_mailer.captain_ride_receipt.subject',
          weekday: @receipt.request.ride.created_at.strftime("%A"),
          timeofday: @receipt.request.ride.created_at.to_datetime.in_time_zone("Pacific Time (US & Canada)").time_of_day,
          savings: "#{@receipt.savings_percentage }%"))
  end

  def stowaway_ride_receipt(receipt_id)
    @receipt = Receipt.find(receipt_id)
    mail(to: @receipt.billed_to,
         subject: I18n.t('mailers.receipt_mailer.stowaway_ride_receipt.subject',
          weekday: @receipt.request.ride.created_at.strftime("%A"),
          timeofday: @receipt.request.ride.created_at.to_datetimei.n_time_zone("Pacific Time (US & Canada)").time_of_day,
          savings: "#{@receipt.savings_percentage }%"))
  end
end