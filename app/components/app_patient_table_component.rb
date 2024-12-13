# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, current_user:, count: nil, heading: nil)
    super

    @patients = patients
    @current_user = current_user
    @count = count
    @heading = heading
  end

  private

  attr_reader :patients, :current_user

  def heading
    @heading.presence || I18n.t("children", count: @count)
  end

  def can_link_to?(patient)
    allowed_patient_ids.include?(patient.id)
  end

  def allowed_patient_ids
    # FIXME: Can we use helpers.policy_scope here?
    # We can remove this once we show a page for the patient that contains
    # limited information for the old organisation.
    @allowed_patient_ids ||=
      PatientPolicy::Scope.new(current_user, Patient).resolve.ids
  end
end
