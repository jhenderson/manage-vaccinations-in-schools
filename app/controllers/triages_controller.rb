# frozen_string_literal: true

class TriagesController < ApplicationController
  include PatientSessionProgrammeConcern
  include TriageMailerConcern

  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_programme
  before_action :set_triage

  after_action :verify_authorized

  def new
    authorize @triage
  end

  def create
    @triage.assign_attributes(triage_params.merge(performed_by: current_user))

    authorize @triage

    if @triage.save(context: :consent)
      StatusUpdater.call(patient: @patient)

      ConsentGrouper
        .call(@patient.reload.consents, programme: @programme)
        .each { send_triage_confirmation(@patient_session, it) }

      flash[:success] = {
        heading: "Triage outcome updated for",
        heading_link_text: @patient.full_name,
        heading_link_href:
          session_patient_programme_path(patient_id: @patient.id)
      }

      redirect_to redirect_path
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  private

  def set_triage
    @triage =
      Triage.new(
        patient: @patient,
        programme: @programme,
        organisation: @session.organisation
      )
  end

  def triage_params
    params.expect(triage: %i[status notes])
  end

  def redirect_path
    if session[:current_section] == "vaccinations"
      session_record_path(@session)
    elsif session[:current_section] == "consents"
      session_consent_path(@session)
    else # if current_section is triage or anything else
      session_triage_path(@session)
    end
  end
end
