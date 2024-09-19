# frozen_string_literal: true

describe CohortImportRow do
  subject(:cohort_import_row) { described_class.new(data:, team:) }

  let(:team) { create(:team) }

  let(:valid_data) do
    {
      "CHILD_ADDRESS_LINE_1" => "10 Downing Street",
      "CHILD_ADDRESS_LINE_2" => "",
      "CHILD_ADDRESS_POSTCODE" => "SW1A 1AA",
      "CHILD_ADDRESS_TOWN" => "London",
      "CHILD_COMMON_NAME" => "Jim",
      "CHILD_DATE_OF_BIRTH" => "2010-01-01",
      "CHILD_FIRST_NAME" => "Jimmy",
      "CHILD_LAST_NAME" => "Smith",
      "CHILD_NHS_NUMBER" => "1234567890",
      "PARENT_1_EMAIL" => "john@example.com",
      "PARENT_1_NAME" => "John Smith",
      "PARENT_1_PHONE" => "07412345678",
      "PARENT_1_RELATIONSHIP" => "Father",
      "SCHOOL_URN" => "123456"
    }
  end

  before { create(:location, :school, urn: "123456") }

  describe "#to_parents" do
    subject(:parents) { cohort_import_row.to_parents }

    let(:data) { valid_data }

    it "returns a parent" do
      expect(parents.count).to eq(1)
      expect(parents.first).to have_attributes(
        name: "John Smith",
        email: "john@example.com",
        phone: "07412345678",
        phone_receive_updates: false
      )
    end

    context "with an existing parent" do
      let!(:existing_parent) do
        create(:parent, name: "John Smith", email: "john@example.com")
      end

      it { should eq([existing_parent]) }

      it "doesn't change phone_receive_updates" do
        expect(parents.first.phone_receive_updates).to eq(
          existing_parent.phone_receive_updates
        )
      end
    end
  end

  describe "#to_patient" do
    subject(:patient) { cohort_import_row.to_patient }

    let(:data) { valid_data }

    it { should_not be_nil }

    describe "#cohort" do
      subject(:cohort) { patient.cohort }

      let(:data) { valid_data.merge("CHILD_DATE_OF_BIRTH" => date_of_birth) }

      context "with a date of birth before September" do
        let(:date_of_birth) { "2000-08-31" }

        it { should have_attributes(team:, reception_starting_year: 2004) }
      end

      context "with a date of birth after September" do
        let(:date_of_birth) { "2000-09-01" }

        it { should have_attributes(team:, reception_starting_year: 2005) }
      end
    end
  end

  describe "#to_parent_relationships" do
    subject(:parent_relationships) do
      cohort_import_row.to_parent_relationships(
        cohort_import_row.to_parents,
        cohort_import_row.to_patient
      )
    end

    let(:data) { valid_data }

    it "returns a parent relationship" do
      expect(parent_relationships.count).to eq(1)
      expect(parent_relationships.first).to be_father
    end
  end
end
