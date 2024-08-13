# frozen_string_literal: true

require "rails_helper"

describe "Immunisation imports" do
  scenario "User uploads a file and views vaccination records" do
    given_i_am_signed_in
    and_an_hpv_campaign_is_underway
    and_school_locations_exist

    when_i_go_to_the_reports_page
    then_i_should_see_the_upload_link

    when_i_click_on_the_upload_link
    then_i_should_see_the_upload_page

    when_i_continue_without_uploading_a_file
    then_i_should_see_an_error

    when_i_upload_an_invalid_file
    then_i_should_see_the_errors_page
    and_i_go_back_to_the_upload_page

    when_i_upload_a_valid_file
    then_i_should_see_the_success_banner
    and_i_should_see_the_upload
    and_i_should_see_the_vaccination_records

    when_i_click_on_a_vaccination_record
    then_i_should_see_the_vaccination_record

    when_i_click_on_vaccination_records
    and_i_should_see_the_vaccination_records
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_campaign_is_underway
    campaign = create(:campaign, :hpv, team: @team)
    location = create(:location, :school)
    @session = create(:session, campaign:, location:)
  end

  def and_school_locations_exist
    create(:location, :school, urn: "110158")
    create(:location, :school, urn: "120026")
    create(:location, :school, urn: "144012")
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"

    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Uploads"
  end

  def then_i_should_see_the_upload_link
    expect(page).to have_link("Upload new vaccination records")
  end

  def when_i_click_on_the_upload_link
    click_on "Upload new vaccination records"
  end

  def then_i_should_see_the_upload_page
    expect(page).to have_content("Upload a report on HPV vaccinations")
  end

  def when_i_continue_without_uploading_a_file
    click_on "Continue"
  end

  def then_i_should_see_an_error
    expect(page).to have_content("There is a problem")
  end

  def when_i_upload_an_invalid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/invalid_rows.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_errors_page
    expect(page).to have_content("The vaccinations could not be added")
    expect(page).to have_content("Row 2")
  end

  def and_i_go_back_to_the_upload_page
    click_on "Back"
  end

  def when_i_upload_a_valid_file
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_success_banner
    expect(page).to have_content("7 vaccinations uploaded")
  end

  def and_i_should_see_the_upload
    expect(page).to have_content("Uploaded on")
    expect(page).to have_content("Uploaded byTest User")
    expect(page).to have_content("CampaignHPV")
  end

  def and_i_should_see_the_vaccination_records
    expect(page).to have_content(
      "Full nameNHS numberDate of birthPostcodeVaccinated date"
    )
    expect(page).to have_content("Full name Chyna Pickle")
    expect(page).to have_content(/NHS number.*742.*018.*0008/)
    expect(page).to have_content("Date of birth 12 September 2012")
    expect(page).to have_content("Postcode LE3 2DA")
    expect(page).to have_content("Vaccinated date 14 May 2024")
  end

  def when_i_click_on_a_vaccination_record
    click_on "Chyna Pickle"
  end

  def when_i_click_on_vaccination_records
    click_on "HPV"
    click_on "Vaccination records"
  end

  def then_i_should_see_the_vaccination_record
    expect(page).to have_content("Chyna Pickle")
    expect(page).to have_content("Child record")
    expect(page).to have_content("NameChyna Pickle")
    expect(page).to have_content("Vaccination record")
    expect(page).to have_content("OutcomeVaccinated")
  end
end
