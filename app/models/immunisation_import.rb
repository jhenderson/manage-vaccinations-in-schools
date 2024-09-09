# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                            :bigint           not null, primary key
#  csv_data                      :text
#  csv_filename                  :text             not null
#  csv_removed_at                :datetime
#  exact_duplicate_record_count  :integer
#  new_record_count              :integer
#  not_administered_record_count :integer
#  processed_at                  :datetime
#  recorded_at                   :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  programme_id                  :bigint           not null
#  uploaded_by_user_id           :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_programme_id         (programme_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  include CSVImportable

  belongs_to :programme

  has_and_belongs_to_many :batches
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :patient_sessions
  has_and_belongs_to_many :patients
  has_and_belongs_to_many :sessions
  has_and_belongs_to_many :vaccination_records

  private

  def required_headers
    %w[
      ORGANISATION_CODE
      SCHOOL_URN
      SCHOOL_NAME
      NHS_NUMBER
      PERSON_FORENAME
      PERSON_SURNAME
      PERSON_DOB
      PERSON_POSTCODE
      DATE_OF_VACCINATION
      VACCINE_GIVEN
      BATCH_NUMBER
      BATCH_EXPIRY_DATE
      ANATOMICAL_SITE
    ]
  end

  def count_columns
    %i[
      exact_duplicate_record_count
      new_record_count
      not_administered_record_count
    ]
  end

  def parse_row(row_data)
    ImmunisationImportRow.new(
      data: row_data,
      programme:,
      user: uploaded_by,
      imported_from: self
    )
  end

  def process_row(row)
    if (vaccination_record = row.to_vaccination_record)
      if vaccination_record.new_record?
        vaccination_record.save!
        :new_record_count
      else
        :exact_duplicate_record_count
      end
    else
      :not_administered_record_count
    end
  end

  def record_rows
    vaccination_records.draft.each do |vaccination_record|
      if (patient_session = vaccination_record.patient_session).draft?
        patient_session.update!(active: true)
      end

      if (session = vaccination_record.session).draft?
        session.update!(active: true)
      end

      vaccination_record.update!(recorded_at: Time.zone.now)
    end
  end
end
