# frozen_string_literal: true

if Settings.disallow_database_seeding
  Rails.logger.info "Database seeding is disabled"
  exit
end

Faker::Config.locale = "en-GB"

def set_feature_flags
  %i[dev_tools mesh_jobs cis2].each do |feature_flag|
    Flipper.add(feature_flag) unless Flipper.exist?(feature_flag)
  end
end

def seed_vaccines
  Rake::Task["vaccines:seed"].execute
end

def import_schools
  if Settings.fast_reset
    FactoryBot.create_list(:location, 30, :primary)
    FactoryBot.create_list(:location, 30, :secondary)
  else
    Rake::Task["schools:import"].execute
  end
end

def create_team(ods_code:)
  team =
    Team.find_by(ods_code:) ||
      FactoryBot.create(:team, :with_generic_clinic, ods_code:)

  programme = Programme.find_by(type: "hpv")
  FactoryBot.create(:team_programme, team:, programme:)

  team
end

def create_user(team:, email: nil, uid: nil)
  if uid
    User.find_by(uid:) ||
      FactoryBot.create(
        :user,
        uid:,
        family_name: "Flo",
        given_name: "Nurse",
        email: "nurse.flo@example.nhs.uk",
        provider: "cis2",
        teams: [team]
        # password: Do not set this as they should not log in via password
      )
  elsif email
    User.find_by(email:) ||
      FactoryBot.create(
        :user,
        family_name: email.split("@").first.split(".").last.capitalize,
        given_name: email.split("@").first.split(".").first.capitalize,
        email:,
        password: email,
        teams: [team]
      )
  else
    raise "No email or UID provided"
  end
end

def attach_sample_of_schools_to(team)
  Location.school.order("RANDOM()").limit(50).update_all(team_id: team.id)
end

def attach_specific_school_to_team_if_present(team:, urn:)
  Location.where(urn:).update_all(team_id: team.id)
end

def create_session(user, team)
  programme = Programme.find_by(type: "hpv")

  FactoryBot.create_list(
    :batch,
    4,
    team:,
    vaccine: programme.vaccines.active.first
  )

  location =
    team.locations.for_year_groups(programme.year_groups).sample ||
      FactoryBot.create(
        :location,
        :school,
        team:,
        year_groups: programme.year_groups
      )

  session = FactoryBot.create(:session, team:, programme:, location:)

  session.dates.create!(value: Date.yesterday)
  session.dates.create!(value: Date.tomorrow)

  patients_without_consent =
    FactoryBot.create_list(:patient_session, 4, programme:, session:, user:)
  unmatched_patients = patients_without_consent.sample(2).map(&:patient)
  unmatched_patients.each do |patient|
    FactoryBot.create(
      :consent_form,
      :recorded,
      programme:,
      given_name: patient.given_name,
      family_name: patient.family_name,
      session:
    )
  end

  %i[
    consent_given_triage_not_needed
    consent_given_triage_needed
    triaged_ready_to_vaccinate
    consent_refused
    consent_conflicting
    vaccinated
    delay_vaccination
    unable_to_vaccinate
  ].each do |trait|
    FactoryBot.create_list(
      :patient_session,
      3,
      trait,
      programme:,
      session:,
      user:
    )
  end

  UnscheduledSessionsFactory.new.call
end

def create_patients(team)
  team.schools.each do |school|
    FactoryBot.create_list(:patient, 5, team:, school:)
  end
end

def create_imports(user, team)
  programme = team.programmes.find_by(type: "hpv")

  %i[pending invalid recorded].each do |status|
    FactoryBot.create(
      :cohort_import,
      status,
      team:,
      programme:,
      uploaded_by: user
    )
    FactoryBot.create(
      :immunisation_import,
      status,
      team:,
      programme:,
      uploaded_by: user
    )
    FactoryBot.create(
      :class_import,
      status,
      team:,
      session: programme.sessions.first,
      uploaded_by: user
    )
  end
end

set_feature_flags

seed_vaccines
import_schools

# Nurse Joy's team
team = create_team(ods_code: "R1L")
user = create_user(team:, email: "nurse.joy@example.com")
create_user(team:, email: "admin.hope@example.com")

attach_sample_of_schools_to(team)
attach_specific_school_to_team_if_present(team:, urn: "136126") # potentially needed for automated testing

Audited.audit_class.as_user(user) { create_session(user, team) }
create_patients(team)
create_imports(user, team)

# CIS2 team - the ODS code and user UID need to match the values in the CIS2 env
team = create_team(ods_code: "A9A5A")
user = create_user(team:, uid: "555057896106")

attach_sample_of_schools_to(team)
attach_specific_school_to_team_if_present(team:, urn: "136126") # potentially needed for automated testing

Audited.audit_class.as_user(user) { create_session(user, team) }
create_patients(team)
create_imports(user, team)
