# frozen_string_literal: true

class GillickAssessmentsController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_programme
  before_action :set_is_first_assessment
  before_action :set_gillick_assessment

  def edit
  end

  def update
    @gillick_assessment.clear_changes_information
    @gillick_assessment.assign_attributes(gillick_assessment_params)

    if !@gillick_assessment.changed? || @gillick_assessment.save
      redirect_to session_patient_programme_path(patient_id: @patient.id)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = policy_scope(Session).find_by!(slug: params[:session_slug])
  end

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession).includes(
        :gillick_assessments,
        session: :programmes
      ).find_by!(session: @session, patient: @patient)
  end

  def set_programme
    @programme =
      @patient_session.programmes.find { it.type == params[:programme_type] }

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_is_first_assessment
    @is_first_assessment = @patient_session.gillick_assessment(@programme).nil?
  end

  def set_gillick_assessment
    @gillick_assessment =
      authorize @patient_session.gillick_assessment(@programme)&.dup ||
                  @patient_session.gillick_assessments.build(
                    programme: @programme
                  )
  end

  def gillick_assessment_params
    params.expect(
      gillick_assessment: %i[
        knows_consequences
        knows_delivery
        knows_disease
        knows_side_effects
        knows_vaccination
        notes
      ]
    ).merge(performed_by: current_user)
  end
end
