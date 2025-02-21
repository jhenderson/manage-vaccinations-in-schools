# frozen_string_literal: true

describe SchoolConsentRequestsJob do
  subject(:perform_now) { described_class.perform_now }

  let(:programmes) { [create(:programme)] }

  let(:parents) { create_list(:parent, 2) }

  let(:patient_with_request_sent) do
    create(:patient, :consent_request_sent, programmes:)
  end
  let(:patient_not_sent_request) { create(:patient, parents:, programmes:) }
  let(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programmes:)
  end
  let(:deceased_patient) { create(:patient, :deceased) }
  let(:invalid_patient) { create(:patient, :invalidated) }
  let(:restricted_patient) { create(:patient, :restricted) }

  let!(:patients) do
    [
      patient_with_request_sent,
      patient_not_sent_request,
      patient_with_consent,
      deceased_patient,
      invalid_patient,
      restricted_patient
    ]
  end

  context "when session is unscheduled" do
    let(:session) { create(:session, :unscheduled, patients:, programmes:) }

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when requests should be sent in the future" do
    let(:session) do
      create(
        :session,
        patients:,
        programmes:,
        send_consent_requests_at: 2.days.from_now
      )
    end

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when requests should be sent today" do
    let(:session) do
      create(
        :session,
        patients:,
        programmes:,
        date: 3.weeks.from_now.to_date,
        send_consent_requests_at: Date.current
      )
    end

    it "sends notifications to one patient" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_request,
        programmes:,
        session:,
        type: :request
      )
      perform_now
    end

    context "with Td/IPV and MenACWY" do
      let(:programmes) do
        [create(:programme, :menacwy), create(:programme, :td_ipv)]
      end

      it "sends one notification to one patient" do
        expect(ConsentNotification).to receive(:create_and_send!).once.with(
          patient: patient_not_sent_request,
          programmes:,
          session:,
          type: :request
        )
        perform_now
      end
    end

    context "when location is a generic clinic" do
      let(:organisation) { create(:organisation, programmes:) }
      let(:location) { create(:generic_clinic, organisation:) }
      let(:session) do
        create(
          :session,
          patients:,
          programmes:,
          send_consent_requests_at: Date.current,
          organisation:
        )
      end

      it "doesn't send any notifications" do
        expect(ConsentNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end
end
