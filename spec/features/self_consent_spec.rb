# frozen_string_literal: true

describe "Self-consent" do
  scenario "From Gillick assessment" do
    given_an_hpv_programme_is_underway
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    then_the_details_of_the_gillick_non_competence_assessment_are_visible
    and_the_child_cannot_give_their_own_consent
    and_the_child_status_reflects_that_there_is_no_consent
    and_the_activity_log_shows_the_gillick_non_competence

    when_the_nurse_edits_the_assessment_the_child_as_gillick_competent
    then_the_details_of_the_gillick_competence_assessment_are_visible
    and_the_activity_log_shows_the_gillick_non_competence
    and_the_activity_log_shows_the_gillick_competence
    and_the_child_can_give_their_own_consent_that_the_nurse_records

    when_the_nurse_views_the_childs_record
    then_they_see_that_the_child_has_consent
    and_the_child_should_be_safe_to_vaccinate
    and_enqueued_jobs_run_with_no_errors
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])

    @school = create(:school)

    @session =
      create(
        :session,
        :today,
        organisation: @organisation,
        programmes: [programme],
        location: @school
      )

    @patient = create(:patient, :consent_no_response, session: @session)
  end

  def and_there_is_a_child_without_parental_consent
    sign_in @organisation.users.first

    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on @school.name
    click_on "Consent"

    choose "No response"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
    expect(page).to have_content(@patient.full_name)
  end

  def when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    click_on @patient.full_name
    click_on "Assess Gillick competence"

    within(
      "fieldset",
      text: "The child knows which vaccination they will have"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows which disease the vaccination protects against"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows what could happen if they got the disease"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows how the injection will be given"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows which side effects they might experience"
    ) { choose "No" }

    fill_in "Assessment notes (optional)",
            with: "They didn't understand the benefits and risks of the vaccine"

    click_on "Complete your assessment"
  end

  def then_the_details_of_the_gillick_non_competence_assessment_are_visible
    expect(page).to have_content("Child assessed as not Gillick competent")
    expect(page).to have_content(
      "They didn't understand the benefits and risks of the vaccine"
    )
  end

  def and_the_child_cannot_give_their_own_consent
    click_on "Get consent"
    expect(page).not_to have_content("Child (Gillick competent)")
    click_on "Back"
  end

  def and_the_child_status_reflects_that_there_is_no_consent
    expect(page).to have_content("No response")
  end

  def and_the_activity_log_shows_the_gillick_non_competence
    click_on "Activity log"
    expect(page).to have_content(
      "Completed Gillick assessment as not Gillick competent"
    )
    click_on "HPV"
  end

  def when_the_nurse_edits_the_assessment_the_child_as_gillick_competent
    click_on "Edit Gillick competence"

    # notes from previous assessment
    expect(page).to have_content(
      "They didn't understand the benefits and risks of the vaccine"
    )

    within(
      "fieldset",
      text: "The child knows which vaccination they will have"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows which disease the vaccination protects against"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows what could happen if they got the disease"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows how the injection will be given"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows which side effects they might experience"
    ) { choose "Yes" }

    fill_in "Assessment notes (optional)",
            with: "They understand the benefits and risks of the vaccine"

    click_on "Update your assessment"
  end

  def then_the_details_of_the_gillick_competence_assessment_are_visible
    expect(page).to have_content("Child assessed as Gillick competent")
    expect(page).to have_content(
      "They understand the benefits and risks of the vaccine"
    )
  end

  def and_the_activity_log_shows_the_gillick_competence
    click_on "Activity log"
    expect(page).to have_content(
      "Updated Gillick assessment as Gillick competent"
    )
    click_on "HPV"
  end

  def and_the_child_can_give_their_own_consent_that_the_nurse_records
    click_on "Get consent"

    # who
    choose "Child (Gillick competent)"
    click_on "Continue"

    # record consent
    choose "Yes, they agree"
    click_on "Continue"

    # notify parents
    choose "Yes"
    click_on "Continue"

    # answer the health questions
    all("label", text: "No").each(&:click)
    click_on "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_on "Continue"

    # confirmation page
    click_on "Confirm"

    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def when_the_nurse_views_the_childs_record
    click_on @patient.full_name, match: :first
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content(
      "#{@patient.full_name} Child (Gillick competent)"
    )
    expect(page).to have_content("Consent given")
  end

  def and_the_child_should_be_safe_to_vaccinate
    expect(page).to have_content("Safe to vaccinate")
  end

  def and_enqueued_jobs_run_with_no_errors
    expect { perform_enqueued_jobs }.not_to raise_error
  end
end
