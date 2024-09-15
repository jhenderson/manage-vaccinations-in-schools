# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                        :bigint           not null, primary key
#  active                    :boolean          default(FALSE), not null
#  close_consent_at          :date
#  date                      :date
#  send_consent_reminders_at :date
#  send_consent_requests_at  :date
#  time_of_day               :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#  programme_id              :bigint
#
# Indexes
#
#  index_sessions_on_programme_id  (programme_id)
#
FactoryBot.define do
  factory :session do
    programme { association :programme, :active }
    location { association :location, :school }

    date { Time.zone.today }
    send_consent_at { date - 14.days }
    send_reminders_at { send_consent_at + 7.days }
    close_consent_at { date }

    time_of_day { %w[morning afternoon all_day].sample }

    active { programme.active }

    trait :active do
      active { true }
    end

    trait :draft do
      active { false }
    end

    trait :in_progress do
      date { Time.zone.now }
    end

    trait :in_future do
      date { Time.zone.now + 1.week }
    end

    trait :in_past do
      date { Time.zone.now - 1.week }
    end

    trait :minimal do
      send_consent_at { nil }
      send_reminders_at { nil }
      close_consent_at { nil }
    end
  end
end
