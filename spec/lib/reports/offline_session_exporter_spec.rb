# frozen_string_literal: true

describe Reports::OfflineSessionExporter do
  def worksheet_to_hashes(worksheet)
    headers = worksheet[0].cells.map(&:value)
    rows =
      (1..worksheet.count - 1).map do |row_num|
        row = worksheet[row_num]
        next if row.nil?
        headers.zip(row.cells.map { |c| c&.value }).to_h
      end
    rows.compact
  end

  def validation_formula(worksheet:, column_name:, row: 1)
    column = worksheet[0].cells.find_index { it.value == column_name.upcase }

    # stree-ignore
    worksheet
      .data_validations
      .find { |validation|
        validation.sqref.any? do
          it.col_range.include?(column) && it.row_range.include?(row)
        end
      }
      .formula1
      .expression
  end

  subject(:call) { described_class.call(session) }

  let(:programme) { create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:user) { create(:user, email: "nurse@example.com", organisation:) }
  let(:team) { create(:team, organisation:) }
  let(:session) { create(:session, location:, organisation:, programme:) }

  context "a school session" do
    subject(:workbook) { RubyXL::Parser.parse_buffer(call) }

    let(:location) { create(:school, team:) }

    it { should_not be_blank }

    describe "headers" do
      subject(:headers) do
        sheet = workbook.worksheets[0]
        sheet[0].cells.map(&:value)
      end

      it do
        expect(headers).to eq(
          %w[
            PERSON_FORENAME
            PERSON_SURNAME
            ORGANISATION_CODE
            SCHOOL_URN
            SCHOOL_NAME
            CARE_SETTING
            PERSON_DOB
            YEAR_GROUP
            PERSON_GENDER_CODE
            PERSON_ADDRESS_LINE_1
            PERSON_POSTCODE
            NHS_NUMBER
            CONSENT_STATUS
            CONSENT_DETAILS
            HEALTH_QUESTION_ANSWERS
            TRIAGE_STATUS
            TRIAGED_BY
            TRIAGE_DATE
            TRIAGE_NOTES
            GILLICK_STATUS
            GILLICK_ASSESSMENT_DATE
            GILLICK_ASSESSED_BY
            GILLICK_ASSESSMENT_NOTES
            VACCINATED
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            PROGRAMME
            VACCINE_GIVEN
            PERFORMING_PROFESSIONAL_EMAIL
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            REASON_NOT_VACCINATED
            NOTES
            SESSION_ID
            UUID
          ]
        )
      end
    end

    describe "rows" do
      subject(:rows) { worksheet_to_hashes(workbook.worksheets[0]) }

      let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }
      let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
      let(:patient_session) { create(:patient_session, patient:, session:) }
      let(:patient) { create(:patient, year_group: 8) }

      it { should be_empty }

      context "with a patient without an outcome" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => 1,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "NOTES" => "",
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_ADDRESS_LINE_1" => patient.address_line_1,
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "PROGRAMME" => "HPV",
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "SESSION_ID" => session.id,
              "TIME_OF_VACCINATION" => "",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "UUID" => "",
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end

      context "with a restricted patient" do
        before { create(:patient, :restricted, session:) }

        it "doesn't include the address or postcode" do
          expect(rows.count).to eq(1)
          expect(rows.first["PERSON_ADDRESS_LINE_1"]).to be_blank
          expect(rows.first["PERSON_POSTCODE"]).to be_blank
        end
      end

      context "with a vaccinated patient" do
        before { create(:patient_session, patient:, session:) }

        let!(:vaccination_record) do
          create(
            :vaccination_record,
            performed_at:,
            batch:,
            patient:,
            session:,
            programme:,
            performed_by: user,
            notes: "Some notes."
          )
        end

        it "adds a row with the vaccination details" do
          expect(rows.count).to eq(1)
          expect(
            rows.first.except(
              "BATCH_EXPIRY_DATE",
              "PERSON_DOB",
              "DATE_OF_VACCINATION"
            )
          ).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 1,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "NOTES" => "Some notes.",
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_ADDRESS_LINE_1" => patient.address_line_1,
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "PROGRAMME" => "HPV",
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "SESSION_ID" => session.id,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["BATCH_EXPIRY_DATE"].to_date).to eq(batch.expiry)
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
          )
        end

        context "with lots of health answers" do
          before do
            create(
              :consent,
              :from_dad,
              patient:,
              programme:,
              health_questions_list: ["First question?", "Second question?"]
            )
          end

          it "separates the answers by new lines" do
            expect(rows.first["HEALTH_QUESTION_ANSWERS"]).to eq(
              "First question? No from Dad\nSecond question? No from Dad"
            )
          end
        end
      end

      context "with a patient who couldn't be vaccinated" do
        before { create(:patient_session, patient:, session:) }

        let!(:vaccination_record) do
          create(
            :vaccination_record,
            :not_administered,
            patient:,
            session:,
            programme:,
            performed_at:,
            performed_by: user,
            notes: "Some notes."
          )
        end

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("DATE_OF_VACCINATION", "PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => nil,
              "CARE_SETTING" => 1,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "DOSE_SEQUENCE" => "",
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "NOTES" => "Some notes.",
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_ADDRESS_LINE_1" => patient.address_line_1,
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "PROGRAMME" => "HPV",
              "REASON_NOT_VACCINATED" => "unwell",
              "SCHOOL_NAME" => location.name,
              "SCHOOL_URN" => location.urn,
              "SESSION_ID" => session.id,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "N",
              "VACCINE_GIVEN" => nil,
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end
    end

    describe "cell validations" do
      subject(:worksheet) { workbook.worksheets[0] }

      before do
        # Without a patient no validation will be setup.
        create(:patient, session:)
      end

      describe "performing professional email" do
        subject(:validation) do
          create(:user, organisation:, email: "vaccinator@example.com")
          validation_formula(
            worksheet:,
            column_name: "performing_professional_email"
          )
        end

        it { should eq "='Performing Professionals'!$A2:$A2" }
      end

      describe "batch number" do
        subject(:validation) do
          create(
            :batch,
            name: "BATCH12345",
            vaccine: programme.vaccines.active.first,
            organisation:
          )
          validation_formula(worksheet:, column_name: "batch_number")
        end

        it { should eq "='hpv Batch Numbers'!$A2:$A2" }
      end
    end

    describe "performing professionals sheet" do
      subject(:worksheet) do
        workbook.worksheets.find { it.sheet_name == "Performing Professionals" }
      end

      let!(:vaccinators) { create_list(:user, 2, organisation:) }

      before do
        create(:patient, session:)
        create(
          :user,
          organisation: create(:organisation),
          email: "vaccinator.other@example.com"
        )
      end

      it "lists all the organisation users' emails" do
        emails = worksheet[1..].map { it.cells.first.value }
        expect(emails).to include(*vaccinators.map(&:email))
      end

      its(:state) { should eq "hidden" }
      its(:sheet_protection) { should be_present }
    end

    describe "batch numbers sheet" do
      subject(:worksheet) do
        workbook.worksheets.find { it.sheet_name == "hpv Batch Numbers" }
      end

      let!(:batches) do
        create_list(
          :batch,
          2,
          vaccine: programme.vaccines.active.first,
          organisation:
        )
      end

      before do
        create(:patient, session:)
        create(:batch, name: "OTHERBATCH", vaccine: create(:vaccine, :flu))
      end

      it "lists all the batch numbers for the programme" do
        batch_numbers = worksheet[1..].map { it.cells.first.value }
        expect(batch_numbers).to include(*batches.map(&:name))
      end

      its(:state) { should eq "hidden" }
      its(:sheet_protection) { should be_present }
    end
  end

  context "a clinic session" do
    subject(:workbook) { RubyXL::Parser.parse_buffer(call) }

    let(:location) { create(:generic_clinic, team:) }

    it { should_not be_blank }

    describe "headers" do
      subject(:headers) do
        sheet = workbook.worksheets[0]
        sheet[0].cells.map(&:value)
      end

      it do
        expect(headers).to eq(
          %w[
            PERSON_FORENAME
            PERSON_SURNAME
            ORGANISATION_CODE
            SCHOOL_URN
            SCHOOL_NAME
            CARE_SETTING
            CLINIC_NAME
            PERSON_DOB
            YEAR_GROUP
            PERSON_GENDER_CODE
            PERSON_ADDRESS_LINE_1
            PERSON_POSTCODE
            NHS_NUMBER
            CONSENT_STATUS
            CONSENT_DETAILS
            HEALTH_QUESTION_ANSWERS
            TRIAGE_STATUS
            TRIAGED_BY
            TRIAGE_DATE
            TRIAGE_NOTES
            GILLICK_STATUS
            GILLICK_ASSESSMENT_DATE
            GILLICK_ASSESSED_BY
            GILLICK_ASSESSMENT_NOTES
            VACCINATED
            DATE_OF_VACCINATION
            TIME_OF_VACCINATION
            PROGRAMME
            VACCINE_GIVEN
            PERFORMING_PROFESSIONAL_EMAIL
            BATCH_NUMBER
            BATCH_EXPIRY_DATE
            ANATOMICAL_SITE
            DOSE_SEQUENCE
            REASON_NOT_VACCINATED
            NOTES
            SESSION_ID
            UUID
          ]
        )
      end
    end

    describe "rows" do
      subject(:rows) { worksheet_to_hashes(workbook.worksheets[0]) }

      it { should be_empty }

      context "with a patient without an outcome" do
        let!(:patient) { create(:patient, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(rows.first.except("PERSON_DOB")).to eq(
            {
              "ANATOMICAL_SITE" => "",
              "BATCH_EXPIRY_DATE" => nil,
              "BATCH_NUMBER" => "",
              "CARE_SETTING" => 2,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "CLINIC_NAME" => "",
              "DATE_OF_VACCINATION" => nil,
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "NOTES" => "",
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "",
              "PERSON_ADDRESS_LINE_1" => patient.address_line_1,
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "PROGRAMME" => "HPV",
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => "",
              "SCHOOL_URN" => "888888",
              "SESSION_ID" => session.id,
              "TIME_OF_VACCINATION" => "",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "",
              "VACCINE_GIVEN" => "",
              "UUID" => "",
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
        end
      end

      context "with a vaccinated patient" do
        let(:patient) do
          create(
            :patient,
            year_group: 8,
            school: create(:school, urn: "123456", name: "Waterloo Road")
          )
        end
        let(:batch) { create(:batch, vaccine: programme.vaccines.active.first) }
        let(:performed_at) { Time.zone.local(2024, 1, 1, 12, 5, 20) }
        let!(:vaccination_record) do
          create(
            :vaccination_record,
            performed_at:,
            batch:,
            patient:,
            session:,
            programme:,
            location_name: "A Clinic",
            performed_by: user,
            notes: "Some notes."
          )
        end

        before { create(:patient_session, patient:, session:) }

        it "adds a row to fill in" do
          expect(rows.count).to eq(1)
          expect(
            rows.first.except(
              "BATCH_EXPIRY_DATE",
              "PERSON_DOB",
              "DATE_OF_VACCINATION"
            )
          ).to eq(
            {
              "ANATOMICAL_SITE" => "left upper arm",
              "BATCH_NUMBER" => batch.name,
              "CARE_SETTING" => 2,
              "CONSENT_DETAILS" => "",
              "CONSENT_STATUS" => "",
              "CLINIC_NAME" => "A Clinic",
              "DOSE_SEQUENCE" => 1,
              "GILLICK_ASSESSED_BY" => nil,
              "GILLICK_ASSESSMENT_DATE" => nil,
              "GILLICK_ASSESSMENT_NOTES" => nil,
              "GILLICK_STATUS" => "",
              "HEALTH_QUESTION_ANSWERS" => "",
              "NHS_NUMBER" => patient.nhs_number,
              "NOTES" => "Some notes.",
              "ORGANISATION_CODE" => organisation.ods_code,
              "PERFORMING_PROFESSIONAL_EMAIL" => "nurse@example.com",
              "PERSON_ADDRESS_LINE_1" => patient.address_line_1,
              "PERSON_FORENAME" => patient.given_name,
              "PERSON_GENDER_CODE" => "Not known",
              "PERSON_POSTCODE" => patient.address_postcode,
              "PERSON_SURNAME" => patient.family_name,
              "PROGRAMME" => "HPV",
              "REASON_NOT_VACCINATED" => "",
              "SCHOOL_NAME" => "Waterloo Road",
              "SCHOOL_URN" => "123456",
              "SESSION_ID" => session.id,
              "TIME_OF_VACCINATION" => "12:05:20",
              "TRIAGED_BY" => nil,
              "TRIAGE_DATE" => nil,
              "TRIAGE_NOTES" => nil,
              "TRIAGE_STATUS" => nil,
              "VACCINATED" => "Y",
              "VACCINE_GIVEN" => "Gardasil9",
              "UUID" => vaccination_record.uuid,
              "YEAR_GROUP" => patient.year_group
            }
          )
          expect(rows.first["BATCH_EXPIRY_DATE"].to_date).to eq(batch.expiry)
          expect(rows.first["PERSON_DOB"].to_date).to eq(patient.date_of_birth)
          expect(rows.first["DATE_OF_VACCINATION"].to_date).to eq(
            performed_at.to_date
          )
        end
      end
    end

    describe "cell validations" do
      subject(:worksheet) { workbook.worksheets[0] }

      before do
        create(:patient, session:)
        create(:user, organisation:, email: "vaccinator@example.com")
      end

      describe "performing professional email" do
        subject(:validation) do
          worksheet = workbook.worksheets[0]
          validation_formula(
            worksheet:,
            column_name: "performing_professional_email"
          )
        end

        it { should eq "='Performing Professionals'!$A2:$A2" }
      end

      describe "batch number" do
        subject(:validation) do
          create(
            :batch,
            name: "BATCH12345",
            vaccine: programme.vaccines.active.first,
            organisation:
          )
          validation_formula(worksheet:, column_name: "batch_number")
        end

        it { should eq "='hpv Batch Numbers'!$A2:$A2" }
      end
    end

    describe "performing professionals sheet" do
      subject(:worksheet) do
        workbook.worksheets.find { it.sheet_name == "Performing Professionals" }
      end

      let!(:vaccinators) { create_list(:user, 2, organisation:) }

      before do
        create(:patient, session:)
        create(
          :user,
          organisation: create(:organisation),
          email: "vaccinator.other@example.com"
        )
      end

      it "lists all the organisation users' emails" do
        emails = worksheet[1..].map { it.cells.first.value }
        expect(emails).to match_array(vaccinators.map(&:email))
      end

      its(:state) { should eq "hidden" }
      its(:sheet_protection) { should be_present }
    end

    describe "batch numbers sheet" do
      subject(:worksheet) do
        workbook.worksheets.find { it.sheet_name == "hpv Batch Numbers" }
      end

      let!(:batches) do
        create_list(
          :batch,
          2,
          vaccine: programme.vaccines.active.first,
          organisation:
        )
      end

      before do
        create(:patient, session:)
        create(:batch, name: "OTHERBATCH", vaccine: create(:vaccine, :flu))
      end

      it "lists all the batch numbers for the programme" do
        batch_numbers = worksheet[1..].map { it.cells.first.value }
        expect(batch_numbers).to match_array(batches.map(&:name))
      end

      its(:state) { should eq "hidden" }
      its(:sheet_protection) { should be_present }
    end
  end
end
