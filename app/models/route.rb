class Route < ActiveRecord::Base
  include Notify::Utils
  belongs_to :start_locale, class_name: 'Locale'
  belongs_to :end_locale, class_name: 'Locale'
  belongs_to :user

  alias_method :start, :start_locale
  alias_method :end, :end_locale

  ADDERS = %w(user request system)
  #TODO: we might want to include less accurate locales that encompass the given locale as well.
  scope :similar_to, ->(route) { where(start_locale_id: route.start_locale_id, end_locale_id: route.end_locale_id).order(accuracy: :desc) }
  scope :have_not_been_notified_in, ->(how_long) { where('last_notified_at IS NULL OR last_notified_at < ?', Time.now - how_long) }

  def has_locales?
    start_locale.present? && end_locale.present?
  end

  def notification_options(opts = {})
    nullified_notification_options(opts) do |options|
      alert = I18n.t("notifications.route.proposed.alert", from_locale: start_locale.name, to_locale: end_locale.name, day: (options[:day] || 'today'), time: (options[:time] || 'now'))
      sound = I18n.t("notifications.route.proposed.sound")

      [alert, sound]
    end
  end
end
