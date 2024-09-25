# frozen_string_literal: true

describe SessionRemindersJob do
  subject(:perform_now) { described_class.perform_now }

  before { Flipper.enable(:scheduled_emails) }

  let(:programme) { create(:programme) }
  let(:parents) { create_list(:parent, 2, :recorded) }
  let(:patient) { create(:patient, parents:) }

  let!(:consent) do
    create(
      :consent,
      :given,
      :recorded,
      patient:,
      parent: parents.first,
      programme:
    )
  end

  context "for an active session tomorrow" do
    let!(:session) do
      create(:session, programme:, date: Date.tomorrow, patients: [patient])
    end
    let(:patient_session) { PatientSession.find_by!(patient:, session:) }

    it "sends an email to the parent who consented" do
      expect { perform_now }.to have_enqueued_mail(
        SessionMailer,
        :reminder
      ).with(params: { consent:, patient_session: }, args: [])
    end

    it "sends a text to the parent who consented" do
      expect { perform_now }.to have_enqueued_text(:session_reminder).with(
        consent:,
        patient_session:
      )
    end

    context "when already sent" do
      before { patient_session.update!(reminder_sent_at: Time.zone.now) }

      it "doesn't send a reminder email" do
        expect { perform_now }.not_to have_enqueued_mail(
          SessionMailer,
          :reminder
        )
      end

      it "doesn't sent a reminder text" do
        expect { perform_now }.not_to have_enqueued_text(:session_reminder)
      end
    end

    it "updates the reminder_sent_at attribute for patient sessions" do
      expect { perform_now }.to(
        change { patient_session.reload.reminder_sent_at }
      )
    end
  end

  context "for a session today" do
    before do
      create(:session, programme:, date: Time.zone.today, patients: [patient])
    end

    it "doesn't send an email" do
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end
  end

  context "for a session yesterday" do
    before do
      create(:session, programme:, date: Date.yesterday, patients: [patient])
    end

    it "doesn't send an email" do
      expect { perform_now }.not_to have_enqueued_mail(SessionMailer, :reminder)
    end
  end
end
