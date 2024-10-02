# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id                                              :bigint           not null, primary key
#  days_before_first_consent_reminder              :integer          default(7), not null
#  days_between_consent_reminders                  :integer          default(7), not null
#  days_between_first_session_and_consent_requests :integer          default(21), not null
#  email                                           :string
#  maximum_number_of_consent_reminders             :integer          default(4), not null
#  name                                            :text             not null
#  ods_code                                        :string           not null
#  phone                                           :string
#  privacy_policy_url                              :string
#  send_updates_by_text                            :boolean          default(FALSE), not null
#  created_at                                      :datetime         not null
#  updated_at                                      :datetime         not null
#  reply_to_id                                     :uuid
#
# Indexes
#
#  index_teams_on_name      (name) UNIQUE
#  index_teams_on_ods_code  (ods_code) UNIQUE
#
class Team < ApplicationRecord
  has_many :cohort_imports
  has_many :cohorts
  has_many :consents
  has_many :locations
  has_many :team_programmes
  has_many :schools, -> { school }, class_name: "Location"
  has_many :sessions

  has_many :patient_sessions, through: :sessions
  has_many :programmes, through: :team_programmes
  has_many :vaccination_records, through: :patient_sessions

  has_and_belongs_to_many :users

  validates :email, presence: true, notify_safe_email: true
  validates :name, presence: true, uniqueness: true
  validates :ods_code, presence: true, uniqueness: true
  validates :phone, presence: true, phone: true

  def year_groups
    programmes.flat_map(&:year_groups).uniq.sort
  end

  def weeks_between_first_session_and_consent_requests
    (days_between_first_session_and_consent_requests / 7).to_i
  end

  def weeks_between_first_session_and_consent_requests=(value)
    self.days_between_first_session_and_consent_requests = value * 7
  end
end
