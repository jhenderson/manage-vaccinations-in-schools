# frozen_string_literal: true

describe BatchPolicy do
  describe "Scope#resolve" do
    subject { BatchPolicy::Scope.new(user, Batch).resolve }

    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation:) }

    let(:batch) { create(:batch, organisation:) }
    let(:archived_batch) { create(:batch, :archived, organisation:) }
    let(:non_organisation_batch) { create(:batch) }

    it { should include(batch) }
    it { should include(archived_batch) }
    it { should_not include(non_organisation_batch) }
  end
end
