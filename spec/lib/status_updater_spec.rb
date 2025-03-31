# frozen_string_literal: true

describe StatusUpdater do
  subject(:call) { described_class.call }

  before { create(:patient_session, patient:, programmes:) }

  context "with an HPV session and ineligible patient" do
    let(:programmes) { [create(:programme, :hpv)] }
    let(:patient) { create(:patient, year_group: 7) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end

    it "doesn't create any triage statuses" do
      expect { call }.not_to change(Patient::TriageStatus, :count)
    end

    it "doesn't create any vaccination statuses" do
      expect { call }.not_to change(Patient::VaccinationStatus, :count)
    end
  end

  context "with an HPV session and eligible patient" do
    let(:programmes) { [create(:programme, :hpv)] }
    let(:patient) { create(:patient, year_group: 8) }

    it "creates a consent status" do
      expect { call }.to change(patient.consent_statuses, :count).by(1)
      expect(patient.consent_statuses.first).to be_no_response
    end

    it "creates a triage status" do
      expect { call }.to change(patient.triage_statuses, :count).by(1)
      expect(patient.triage_statuses.first).to be_not_required
    end

    it "creates a vaccination status" do
      expect { call }.to change(patient.vaccination_statuses, :count).by(1)
      expect(patient.vaccination_statuses.first).to be_none_yet
    end
  end

  context "with a doubles session and ineligible patient" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end
    let(:patient) { create(:patient, year_group: 8) }

    it "doesn't create any consent statuses" do
      expect { call }.not_to change(Patient::ConsentStatus, :count)
    end

    it "doesn't create any triage statuses" do
      expect { call }.not_to change(Patient::TriageStatus, :count)
    end

    it "doesn't create any vaccination statuses" do
      expect { call }.not_to change(Patient::VaccinationStatus, :count)
    end
  end

  context "with an doubles session and eligible patient" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end
    let(:patient) { create(:patient, year_group: 9) }

    it "creates a consent status for both programmes" do
      expect { call }.to change(patient.consent_statuses, :count).by(2)
      expect(patient.consent_statuses.first).to be_no_response
      expect(patient.consent_statuses.second).to be_no_response
    end

    it "creates a triage status for both programmes" do
      expect { call }.to change(patient.triage_statuses, :count).by(2)
      expect(patient.triage_statuses.first).to be_not_required
      expect(patient.triage_statuses.second).to be_not_required
    end

    it "creates a vaccination status for both programmes" do
      expect { call }.to change(patient.vaccination_statuses, :count).by(2)
      expect(patient.vaccination_statuses.first).to be_none_yet
      expect(patient.vaccination_statuses.second).to be_none_yet
    end
  end
end
