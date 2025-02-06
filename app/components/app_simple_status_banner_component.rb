# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  delegate :status, to: :@patient_session

  private

  def who_refused
    @patient_session
      .consents
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
  end

  def full_name
    @patient_session.patient.full_name
  end

  def nurse
    most_recent_event = [
      @patient_session.latest_triage,
      @patient_session.vaccination_records.last
    ].compact.max_by(&:created_at)

    most_recent_event&.performed_by&.full_name
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end
end
