# frozen_string_literal: true

describe "Pilot - upload cohort" do
  scenario "User uploads a cohort list" do
    given_the_app_is_setup
    and_an_hpv_programme_is_underway

    when_i_visit_the_cohort_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_cohort
    then_i_should_see_the_upload_cohort_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_a_malformed_csv
    then_i_should_see_an_error

    when_i_upload_a_cohort_file_with_invalid_headers
    then_i_should_the_errors_page_with_invalid_headers

    when_i_upload_a_cohort_file_with_invalid_fields
    then_i_should_the_errors_page_with_invalid_fields
    and_i_should_be_able_to_go_to_the_upload_page

    when_i_upload_the_cohort_file
    then_i_should_see_the_success_page
  end

  def given_the_app_is_setup
    @team = create(:team, :with_one_nurse)
    create(:location, :school, urn: "123456")
    @user = @team.users.first
  end

  def and_an_hpv_programme_is_underway
    create(:programme, :hpv, academic_year: 2023, team: @team)
  end

  def when_i_visit_the_cohort_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
  end

  def and_i_start_adding_children_to_the_cohort
    click_on "Add children to programme cohort"
  end

  def then_i_should_see_the_upload_cohort_page
    expect(page).to have_content("Upload the cohort list")
  end

  def when_i_upload_the_cohort_file
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/valid_cohort.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_see_the_success_page
    expect(page).to have_content("Cohort data uploaded")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Upload the cohort list"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_a_malformed_csv
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/malformed.csv"
    )
    click_on "Upload the cohort list"
  end

  def when_i_upload_a_cohort_file_with_invalid_headers
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/invalid_headers.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_the_errors_page_with_invalid_headers
    expect(page).to have_content("The file is missing the following headers")
  end

  def when_i_upload_a_cohort_file_with_invalid_fields
    attach_file(
      "cohort_import[csv]",
      "spec/fixtures/cohort_import/invalid_fields.csv"
    )
    click_on "Upload the cohort list"
  end

  def then_i_should_the_errors_page_with_invalid_fields
    expect(page).to have_content("The cohort list could not be added")
    expect(page).to have_content("Row 2")
  end

  def and_i_should_be_able_to_go_to_the_upload_page
    click_on "Upload a new cohort list"
  end
end
