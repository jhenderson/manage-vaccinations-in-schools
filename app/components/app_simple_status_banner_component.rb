# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def call
    render AppCardComponent.new(colour:) do |card|
      card.with_heading { heading }

      safe_join(
        [
          tag.p(description),
          if (link = update_triage_outcome_link)
            tag.p(link)
          end
        ]
      )
    end
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def status
    @status ||= patient_session.status(programme:)
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def description
    options = {
      default: "",
      full_name: patient.full_name,
      nurse:,
      who_refused:,
      programme_name: programme.name
    }

    if patient.triage_outcome.required?(programme)
      reasons = [
        if patient.triage_outcome.consent_needs_triage?(programme:)
          I18n.t(
            :consent_needs_triage,
            scope: %i[
              patient_session_statuses
              consent_given_triage_needed
              banner_explanation
            ],
            **options
          )
        end,
        if patient.triage_outcome.vaccination_history_needs_triage?(programme:)
          I18n.t(
            :vaccination_partially_administered,
            scope: %i[
              patient_session_statuses
              consent_given_triage_needed
              banner_explanation
            ],
            **options
          )
        end
      ].compact

      safe_join(reasons, tag.br)
    else
      I18n.t("patient_session_statuses.#{status}.banner_explanation", **options)
    end
  end

  def who_refused
    patient.consent_outcome.latest[programme]
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
  end

  def nurse
    (
      patient.triage_outcome.all[programme] +
        patient.programme_outcome.all[programme]
    ).max_by(&:updated_at)&.performed_by&.full_name
  end

  def update_triage_outcome_link
    unless status.in?(
             %w[
               delay_vaccination
               triaged_ready_to_vaccinate
               triaged_do_not_vaccinate
             ]
           ) && helpers.policy(Triage).edit?
      return
    end

    link_to(
      "Update triage outcome",
      new_session_patient_programme_triages_path(session, patient, programme)
    )
  end
end
