# frozen_string_literal: true

describe SessionAttendancePolicy do
  subject(:policy) { described_class.new(user, session_attendance) }

  let(:user) { create(:nurse) }

  let(:programme) { create(:programme) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:session) { create(:session, organisation:, programmes: [programme]) }
  let(:patient) { create(:patient) }
  let(:patient_session) { create(:patient_session, patient:, session:) }

  shared_examples "allow if not yet seen by nurse" do
    context "with a new session attendance" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      it { should be(true) }
    end

    context "with session attendance and a vaccination record" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme:,
          performed_at: Time.current
        )
      end

      it { should be(false) }
    end

    context "with session attendance and a vaccination record from a different date" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme:,
          performed_at: Time.zone.yesterday
        )
      end

      it { should be(true) }
    end
  end

  describe "#new?" do
    subject(:new?) { policy.new? }

    include_examples "allow if not yet seen by nurse"
  end

  describe "#create?" do
    subject(:create?) { policy.create? }

    include_examples "allow if not yet seen by nurse"
  end

  describe "#edit?" do
    subject(:edit?) { policy.edit? }

    include_examples "allow if not yet seen by nurse"
  end

  describe "#update?" do
    subject(:update?) { policy.update? }

    include_examples "allow if not yet seen by nurse"
  end
end
