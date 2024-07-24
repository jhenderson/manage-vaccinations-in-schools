# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id          :bigint           not null, primary key
#  csv         :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_campaign_id  (campaign_id)
#  index_immunisation_imports_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

describe ImmunisationImport, type: :model do
  subject(:immunisation_import) { create(:immunisation_import, csv:, user:) }

  let(:file) { "nivs.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:team) { create(:team, ods_code: "R1L") }
  let(:user) { create(:user, teams: [team]) }

  it { should validate_presence_of(:csv) }

  describe "#load_data!" do
    before { immunisation_import.load_data! }

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/correct format/)
      end
    end

    describe "with empty CSV" do
      let(:file) { "empty.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/one record/)
      end
    end

    describe "with missing headers" do
      let(:file) { "missing_headers.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/missing/)
      end
    end
  end

  describe "#parse_rows!" do
    before { immunisation_import.parse_rows! }

    it "populates the rows" do
      expect(immunisation_import).to be_valid
      expect(immunisation_import.rows).not_to be_empty
    end

    describe "with invalid rows" do
      let(:file) { "invalid_rows.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors).to include(:row_2)
      end
    end
  end

  describe "#process!" do
    it "creates locations, patients, and vaccination records" do
      # stree-ignore
      expect { immunisation_import.process! }
        .to change(immunisation_import.vaccination_records, :count).by(11)
        .and change(immunisation_import.locations, :count).by(4)
        .and change(immunisation_import.patients, :count).by(11)
        .and change(immunisation_import.sessions, :count).by(4)
        .and change(PatientSession, :count).by(11)

      # Second import should not duplicate the vaccination records if they're
      # identical.

      # stree-ignore
      expect { immunisation_import.process! }
        .to not_change(immunisation_import.vaccination_records, :count)
        .and not_change(immunisation_import.locations, :count)
        .and not_change(immunisation_import.patients, :count)
        .and not_change(immunisation_import.sessions, :count)
        .and not_change(PatientSession, :count)
    end
  end
end
