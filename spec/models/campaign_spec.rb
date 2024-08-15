# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  end_date      :date
#  name          :string           not null
#  start_date    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
require "rails_helper"

describe Campaign, type: :model do
  subject(:campaign) do
    build(:campaign, academic_year: 2024, start_date: Date.new(2024, 6, 1))
  end

  describe "validations" do
    it { should validate_presence_of(:academic_year) }

    it do
      expect(campaign).to validate_comparison_of(
        :academic_year
      ).is_greater_than_or_equal_to(2000).is_less_than_or_equal_to(
        Time.zone.today.year + 5
      )
    end

    it do
      expect(campaign).to validate_comparison_of(
        :start_date
      ).is_greater_than_or_equal_to(Date.new(2024, 1, 1))
    end

    it do
      expect(campaign).to validate_comparison_of(
        :end_date
      ).is_greater_than_or_equal_to(
        Date.new(2024, 6, 1)
      ).is_less_than_or_equal_to(Date.new(2025, 12, 31))
    end
  end
end
