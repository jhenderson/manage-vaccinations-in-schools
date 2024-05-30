class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient_session)
    super

    @patient_session = patient_session
  end

  def events_by_day
    all_events
      .sort_by { -_1[:time].to_i }
      .group_by { _1[:time].to_fs(:nhsuk_date) }
  end

  def all_events
    [session_events, consent_events].flatten
  end

  def consent_events
    @patient_session.patient.consents.recorded.map do
      {
        title:
          "Consent #{_1.response} by #{_1.parent_name} (#{_1.who_responded})",
        time: _1.recorded_at
      }
    end
  end

  def session_events
    [
      {
        title:
          "Invited to session at #{@patient_session.session.location.name}",
        time: @patient_session.created_at
      }
    ]
  end
end
