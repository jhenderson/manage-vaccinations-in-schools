# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientsHelper, type: :helper do
  describe "#format_nhs_number" do
    subject(:formatted_nhs_number) { helper.format_nhs_number(nhs_number) }

    context "when the NHS number is present" do
      let(:nhs_number) { "0123456789" }

      it { should be_html_safe }
      it { should eq("<span class=\"app-u-monospace\">012 345 6789</span>") }
    end

    context "when the NHS number is not present" do
      let(:nhs_number) { nil }

      it { should_not be_html_safe }
      it { should eq("Not provided") }
    end
  end
end
