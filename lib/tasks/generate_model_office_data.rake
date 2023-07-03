require "faker"

desc "Generate test scenarios to support the model office"
task :generate_model_office_data, [] => :environment do |_task, _args|
  Faker::Config.locale = "en-GB"
  target_filename = "db/sample_data/model-office.json"

  hpv_vaccine = {
    brand: "Gardasil 9",
    method: "Injection",
    batches: [
      { name: "IE5343", expiry: "2024-02-01" },
      { name: "IE6279", expiry: "2024-01-18" },
      { name: "IE3943", expiry: "2024-01-25" }
    ]
  }

  school_details = {
    urn: "139714",
    name: "The Portsmouth Academy",
    address: "St Mary's Road",
    locality: "",
    address3: "",
    town: "Portsmouth",
    county: "Hampshire",
    postcode: "PO1 5PF",
    minimum_age: "11",
    maximum_age: "16",
    url: "https://www.theportsmouthacademy.org.uk/",
    phase: "Secondary",
    type: "Academy sponsor led",
    detailed_type: "Academy sponsor led"
  }

  patients_and_consents = []

  # about 50% yes from parent or guardian, no yes answers or notes, in state ready to vaccinate
  100.times do
    patient = FactoryBot.build(:patient, :of_hpv_vaccination_age)
    who_from = %i[from_mum from_dad].sample
    consent =
      FactoryBot.build(
        :consent_response,
        :given,
        who_from,
        :health_question_hpv_no_contraindications,
        patient:,
        campaign: nil
      )
    patients_and_consents << [patient, consent]
  end

  patients_data = patients_and_consents.map do |patient, consent|
    {
      firstName: patient.first_name,
      lastName: patient.last_name,
      dob: patient.dob.iso8601,
      nhsNumber: patient.nhs_number,
      consent: {
        consent: consent.consent,
        parentName: consent.parent_name,
        parentRelationship: consent.parent_relationship,
        parentEmail: consent.parent_email,
        parentPhone: consent.parent_phone,
        healthQuestionResponses: consent.health_questions,
        route: consent.route
      }
    }
  end

  data = {
    id: "5M0",
    title: "HPV campaign at #{school_details[:name]}",
    location: school_details[:name],
    date: "2023-07-11T12:30",
    type: "HPV",
    vaccines: [hpv_vaccine],
    school: school_details,
    patients: patients_data,
  }

  File.open(target_filename, "w") { |f| f << JSON.pretty_generate(data) }
end
