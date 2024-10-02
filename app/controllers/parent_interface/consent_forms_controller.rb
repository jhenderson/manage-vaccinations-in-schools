# frozen_string_literal: true

module ParentInterface
  class ConsentFormsController < ConsentForms::BaseController
    include ConsentFormMailerConcern

    prepend_before_action :set_session_and_programme,
                          only: %i[start create deadline_passed]
    skip_before_action :set_consent_form, only: %i[start create deadline_passed]
    skip_before_action :authenticate_consent_form_user!,
                       only: %i[start create deadline_passed]

    before_action :clear_session_edit_variables, only: %i[confirm]
    before_action :check_if_past_deadline, except: %i[deadline_passed]

    def start
    end

    def create
      consent_form =
        ConsentForm.create!(
          programme: @programme,
          team: @session.team,
          location: @session.location
        )

      session[:consent_form_id] = consent_form.id

      redirect_to parent_interface_consent_form_edit_path(consent_form, :name)
    end

    def cannot_consent_responsibility
    end

    def deadline_passed
    end

    def confirm
    end

    def record
      @consent_form.update!(recorded_at: Time.zone.now)

      session.delete(:consent_form_id)

      send_consent_form_confirmation(@consent_form)

      ConsentFormMatchingJob.perform_later(@consent_form)
    end

    private

    def set_session_and_programme
      @session = Session.find(params[:session_id])
      @programme = @session.programmes.find(params[:programme_id])
      @team = @session.team
    end

    def clear_session_edit_variables
      session.delete(:follow_up_changes_start_page)
    end

    def check_if_past_deadline
      return if @session.open_for_consent?
      redirect_to action: :deadline_passed
    end
  end
end
