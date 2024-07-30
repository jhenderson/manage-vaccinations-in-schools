# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccines
#
#  id                  :bigint           not null, primary key
#  brand               :text             not null
#  dose                :decimal(, )      not null
#  gtin                :text
#  manufacturer        :text             not null
#  method              :integer          not null
#  nivs_name           :text             not null
#  snomed_product_code :string           not null
#  snomed_product_term :string           not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_vaccines_on_gtin                    (gtin) UNIQUE
#  index_vaccines_on_manufacturer_and_brand  (manufacturer,brand) UNIQUE
#  index_vaccines_on_nivs_name               (nivs_name) UNIQUE
#  index_vaccines_on_snomed_product_code     (snomed_product_code) UNIQUE
#  index_vaccines_on_snomed_product_term     (snomed_product_term) UNIQUE
#
FactoryBot.define do
  factory :vaccine do
    transient { batch_count { 1 } }

    type { %w[flu hpv].sample }
    brand { Faker::Commerce.product_name }
    manufacturer { Faker::Company.name }
    nivs_name { brand }
    dose { Faker::Number.decimal(l_digits: 0) }
    snomed_product_code { Faker::Number.decimal_part(digits: 17) }
    snomed_product_term { Faker::Lorem.sentence }
    add_attribute(:method) { %i[nasal injection].sample }

    traits_for_enum :method

    after(:create) do |vaccine, evaluator|
      create_list(:batch, evaluator.batch_count, vaccine:)
    end

    trait :flu do
      type { "flu" }

      after(:create) do |vaccine|
        asthma = create(:health_question, :asthma, vaccine:)
        steroids = create(:health_question, :steroids, vaccine:)
        intensive_care = create(:health_question, :intensive_care, vaccine:)
        flu_vaccination = create(:health_question, :flu_vaccination, vaccine:)
        immune_system = create(:health_question, :immune_system, vaccine:)
        household_immune_system =
          create(:health_question, :household_immune_system, vaccine:)
        egg_allergy = create(:health_question, :egg_allergy, vaccine:)
        allergies = create(:health_question, :allergies, vaccine:)
        reaction = create(:health_question, :reaction, vaccine:)
        aspirin = create(:health_question, :aspirin, vaccine:)

        asthma.update! next_question: flu_vaccination
        asthma.update! follow_up_question: steroids
        steroids.update! next_question: intensive_care
        intensive_care.update! next_question: flu_vaccination

        flu_vaccination.update! next_question: immune_system
        immune_system.update! next_question: household_immune_system
        household_immune_system.update! next_question: egg_allergy
        egg_allergy.update! next_question: allergies
        allergies.update! next_question: reaction
        reaction.update! next_question: aspirin
      end
    end

    trait :flucelvax_tetra do
      flu
      injection
      brand { "Flucelvax Tetra - QIVc" }
      manufacturer { "Seqirus" }
      nivs_name { "Seqirus Flucelvax Tetra QIVC" }
      snomed_product_code { "36509011000001106" }
      snomed_product_term do
        "Flucelvax Tetra vaccine suspension for injection 0.5ml" \
          " pre-filled syringes (Seqirus UK Ltd) (product)"
      end
      dose { 0.5 }
    end

    trait :fluenz_tetra do
      flu
      nasal
      type { "flu" }
      brand { "Fluenz Tetra - LAIV" }
      manufacturer { "AstraZeneca" }
      nivs_name { "AstraZeneca Fluenz Tetra LAIV" }
      snomed_product_code { "27114211000001105" }
      snomed_product_term do
        "Fluenz Tetra vaccine nasal suspension 0.2ml unit dose (AstraZeneca UK Ltd) (product)"
      end
      dose { 0.2 }
    end

    trait :quadrivalent_influenza do
      flu
      injection
      brand { "Quadrivalent Influenza vaccine - QIVe" }
      manufacturer { "Sanofi" }
      nivs_name { "Sanofi Pasteur QIVe" }
      snomed_product_code { "34680411000001107" }
      snomed_product_term do
        "Quadrivalent influenza vaccine (split virion, inactivated) suspension" \
          " for injection 0.5ml pre-filled syringes (Sanofi) (product)"
      end
      dose { 0.5 }
    end

    trait :hpv do
      type { "hpv" }

      after(:create) do |vaccine|
        severe_allergies = create(:health_question, :severe_allergies, vaccine:)
        medical_conditions =
          create(:health_question, :medical_conditions, vaccine:)
        severe_reaction = create(:health_question, :severe_reaction, vaccine:)

        severe_allergies.update! next_question: medical_conditions
        medical_conditions.update! next_question: severe_reaction
      end
    end

    trait :cervaris do
      hpv
      injection
      brand { "Cervarix" }
      manufacturer { "GlaxoSmithKline" }
      nivs_name { "Cervarix" }
      snomed_product_code { "12238911000001100" }
      snomed_product_term do
        "Cervarix vaccine suspension for injection 0.5ml pre-filled syringes (GlaxoSmithKline) (product)"
      end
      dose { 0.5 }
    end

    trait :gardasil do
      hpv
      injection
      brand { "Gardasil" }
      manufacturer { "Merck Sharp & Dohme" }
      nivs_name { "Gardasil" }
      snomed_product_code { "10880211000001104" }
      snomed_product_term do
        "Gardasil vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd) (product)"
      end
      dose { 0.5 }
    end

    trait :gardasil_9 do
      hpv
      injection
      brand { "Gardasil 9" }
      manufacturer { "Merck Sharp & Dohme" }
      nivs_name { "Gardasil9" }
      snomed_product_code { "33493111000001108" }
      snomed_product_term do
        "Gardasil 9 vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd) (product)"
      end
      dose { 0.5 }
    end
  end
end
