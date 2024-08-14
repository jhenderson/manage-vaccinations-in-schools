# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  academic_year :integer          not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  team_id       :integer
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
FactoryBot.define do
  factory :campaign do
    transient { batch_count { 1 } }

    academic_year { Time.zone.today.year }

    team
    hpv

    trait :hpv do
      name { "HPV" }
      vaccines do
        [
          create(:vaccine, :cervarix, batch_count:),
          create(:vaccine, :gardasil, batch_count:),
          create(:vaccine, :gardasil_9, batch_count:)
        ]
      end
    end

    trait :hpv_no_batches do
      transient { batch_count { 0 } }
      hpv
    end

    trait :flu do
      name { "Flu" }
      vaccines do
        [
          create(:vaccine, :adjuvanted_quadrivalent, batch_count:),
          create(:vaccine, :cell_quadrivalent, batch_count:),
          create(:vaccine, :fluad_tetra, batch_count:),
          create(:vaccine, :flucelvax_tetra, batch_count:),
          create(:vaccine, :fluenz_tetra, batch_count:),
          create(:vaccine, :quadrivalent_influenza, batch_count:),
          create(:vaccine, :quadrivalent_influvac_tetra, batch_count:),
          create(:vaccine, :supemtek, batch_count:)
        ]
      end
    end

    trait :flu_nasal_only do
      name { "Flu" }
      vaccines { [create(:vaccine, :fluenz_tetra, batch_count:)] }
    end
  end
end
