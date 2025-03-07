# frozen_string_literal: true

class AppSessionDetailsSummaryComponent < ViewComponent::Base
  def initialize(session, patient_sessions:)
    super

    @session = session
    @patient_sessions = patient_sessions
  end

  def call
    govuk_summary_list(rows:)
  end

  private

  attr_reader :session, :patient_sessions

  def rows
    [cohort_row, ready_for_vaccinator_row, vaccinated_row]
  end

  def cohort_row
    count = patient_sessions.length
    href = new_draft_class_import_path(session)

    {
      key: {
        text: "Cohort"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Import class lists", href: }]
    }
  end

  def ready_for_vaccinator_row
    count =
      patient_sessions.count do
        it
          .patient
          .programme_outcome
          .status
          .values_at(*it.programmes)
          .none?(Patient::ProgrammeOutcome::VACCINATED) &&
          it.register_outcome.attending?
      end

    href =
      session_record_path(
        session,
        search_form: {
          session_status: PatientSession::SessionOutcome::NONE
        }
      )

    {
      key: {
        text: "Ready for vaccinator"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def vaccinated_row
    count =
      patient_sessions.count do
        it.session_outcome.status.values.include?(
          PatientSession::SessionOutcome::VACCINATED
        )
      end

    href =
      session_record_path(
        session,
        search_form: {
          session_status: PatientSession::SessionOutcome::VACCINATED
        }
      )

    {
      key: {
        text: "Vaccinated"
      },
      value: {
        text: "#{pluralize(count, "vaccination")} given"
      },
      actions: [{ text: "Review", href: }]
    }
  end
end
