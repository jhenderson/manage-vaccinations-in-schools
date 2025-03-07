# frozen_string_literal: true

describe "HPV vaccination" do
  scenario "Delayed (unwell)" do
    given_i_am_signed_in

    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    and_i_record_that_the_patient_was_unwell
    then_i_see_the_confirmation_page

    when_i_confirm_the_details
    then_i_still_see_the_patient_in_the_record_tab
    and_a_success_message

    when_i_go_to_the_patient
    then_i_see_that_the_status_is_delayed

    when_i_go_to_the_outcome_tab
    then_i_see_the_patient_has_no_outcome_yet

    when_vaccination_confirmations_are_sent
    then_an_email_is_sent_to_the_parent_confirming_the_delay
    and_a_text_is_sent_to_the_parent_confirming_the_delay
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    @organisation = create(:organisation, :with_one_nurse, programmes:)

    location = create(:school)
    @batch =
      create(
        :batch,
        organisation: @organisation,
        vaccine: programmes.first.vaccines.first
      )

    @session =
      create(:session, organisation: @organisation, programmes:, location:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in @organisation.users.first
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_record_path(@session)
    click_link @patient.full_name
  end

  def and_i_record_that_the_patient_was_unwell
    within(
      "fieldset",
      text:
        "Does the child know what the vaccination is for, and are they happy to have it?"
    ) { choose "Yes" }

    within(
      "fieldset",
      text:
        "Has the child confirmed they have not already had this vaccination?"
    ) { choose "Yes" }

    within("fieldset", text: "Is the child is feeling well?") { choose "No" }

    within(
      "fieldset",
      text:
        "Has the child confirmed they have no allergies which would prevent vaccination?"
    ) { choose "Yes" }

    find_all(".nhsuk-fieldset")[4].choose "No"
    click_button "Continue"

    choose "They were not well enough"
    click_button "Continue"
  end

  def then_i_see_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("Child#{@patient.full_name}")
    expect(page).to have_content("OutcomeUnwell")
  end

  def when_i_confirm_the_details
    click_button "Confirm"
  end

  def then_i_still_see_the_patient_in_the_record_tab
    expect(page).to have_content("Showing 1 to 1 of 1 children")
    expect(page).to have_content(@patient.full_name)
  end

  def and_a_success_message
    expect(page).to have_content("Record updated for #{@patient.full_name}")
  end

  def when_i_go_to_the_patient
    click_link @patient.full_name, match: :first
  end

  def then_i_see_that_the_status_is_delayed
    expect(page).to have_content("Could not vaccinate")
  end

  def when_i_go_to_the_outcome_tab
    click_on "Back to session"
    click_on "Session outcomes"
  end

  def then_i_see_the_patient_has_no_outcome_yet
    expect(page).to have_content("Status\nHPVUnwell")
  end

  def when_vaccination_confirmations_are_sent
    VaccinationConfirmationsJob.perform_now
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_delay
    expect_email_to(
      @patient.consents.last.parent.email,
      :vaccination_confirmation_not_administered
    )
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_delay
    expect_sms_to(
      @patient.consents.last.parent.phone,
      :vaccination_confirmation_not_administered
    )
  end
end
