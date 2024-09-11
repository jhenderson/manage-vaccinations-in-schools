# frozen_string_literal: true

describe "Immunisation imports duplicates" do
  before { Flipper.enable(:import_review) }

  scenario "User reviews and selects between duplicate records" do
    given_i_am_signed_in
    and_an_hpv_programme_is_underway
    and_an_existing_patient_record_exists

    when_i_go_to_the_reports_page
    and_i_click_on_the_upload_link
    and_i_upload_a_file_with_duplicate_records
    then_i_should_see_the_edit_page_with_duplicate_records

    when_i_review_the_duplicate_record
    then_i_should_see_the_duplicate_record

    when_i_submit_the_form_without_choosing_anything
    then_i_should_see_a_validation_error

    when_i_select_the_duplicate_record
    and_i_confirm_my_selection
    then_i_should_see_a_success_message
    and_the_record_should_be_updated
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, ods_code: "R1L")
    sign_in @team.users.first
  end

  def and_an_hpv_programme_is_underway
    @programme =
      create(:programme, :hpv_all_vaccines, academic_year: 2023, team: @team)
    @location = create(:location, :school, urn: "110158")
    @session =
      create(
        :session,
        programme: @programme,
        location: @location,
        date: Date.new(2024, 5, 14),
        time_of_day: :all_day
      )
  end

  def and_an_existing_patient_record_exists
    @existing_patient =
      create(
        :patient,
        first_name: "Esmae",
        last_name: "O'Connell",
        nhs_number: "7420180008", # First row of valid_hpv.csv
        date_of_birth: Date.new(2014, 3, 29),
        gender_code: :female,
        address_postcode: "QG53 3OA",
        school: @location
      )
    @already_vaccinated_patient =
      create(
        :patient,
        first_name: "Caden",
        last_name: "Attwater",
        nhs_number: "4146825652", # Third row of valid_hpv.csv
        date_of_birth: Date.new(2012, 9, 14),
        gender_code: :male,
        address_postcode: "LE1 2DA",
        school: @location
      )
    @patient_session =
      create(
        :patient_session,
        patient: @already_vaccinated_patient,
        session: @session
      )
    @vaccine = @programme.vaccines.find_by(nivs_name: "Gardasil9")
    @batch =
      create(
        :batch,
        vaccine: @vaccine,
        expiry: Date.new(2022, 7, 30),
        name: "123013325"
      )
    @previous_vaccination_record =
      create(
        :vaccination_record,
        administered_at: @session.date.in_time_zone + 12.hours,
        notes: "Foo",
        recorded_at: Time.zone.yesterday,
        batch: @batch,
        delivery_method: :intramuscular,
        delivery_site: :left_thigh,
        dose_sequence: 1,
        patient_session: @patient_session,
        vaccine: @vaccine
      )
  end

  def when_i_go_to_the_reports_page
    visit "/dashboard"
    click_on "Vaccination programmes", match: :first
    click_on "HPV"
    click_on "Uploads"
  end

  def and_i_click_on_the_upload_link
    click_on "Upload new vaccination records"
  end

  def and_i_upload_a_file_with_duplicate_records
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"
  end

  def then_i_should_see_the_edit_page_with_duplicate_records
    expect(page).to have_content("1 duplicate record needs review")
  end

  def when_i_select_the_duplicate_record
    choose "Use duplicate record"
  end

  def when_i_submit_the_form_without_choosing_anything
    click_on "Resolve duplicate"
  end
  alias_method :and_i_confirm_my_selection,
               :when_i_submit_the_form_without_choosing_anything

  def then_i_should_see_a_success_message
    expect(page).to have_content("Vaccination record updated")
  end

  def when_i_review_the_duplicate_record
    click_on "Review Esmae O'Connell"
  end

  def then_i_should_see_the_duplicate_record
    expect(page).to have_content("This record needs reviewing")
  end

  def and_the_record_should_be_updated
    @existing_patient.reload
    expect(@existing_patient.first_name).to eq("Chyna")
    expect(@existing_patient.last_name).to eq("Pickle")
    expect(@existing_patient.pending_changes).to eq({})
  end

  def then_i_should_see_a_validation_error
    expect(page).to have_content("There is a problem")
  end
end
