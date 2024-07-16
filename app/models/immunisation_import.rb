# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id         :bigint           not null, primary key
#  csv        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  attr_accessor :csv_is_malformed, :data, :rows

  belongs_to :user
  has_many :vaccination_records,
           dependent: :restrict_with_exception,
           foreign_key: :imported_from_id
  has_many :locations,
           dependent: :restrict_with_exception,
           foreign_key: :imported_from_id

  EXPECTED_HEADERS = %w[
    ANATOMICAL_SITE
    DATE_OF_VACCINATION
    ORGANISATION_CODE
    SCHOOL_NAME
    SCHOOL_URN
    VACCINATED
  ].freeze

  validates :csv, presence: true
  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid
  validate :rows_are_valid

  def csv=(value)
    super(value.respond_to?(:read) ? value.read : value)
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  ensure
    csv.close if csv.respond_to?(:close)
  end

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows = data.map { |row_data| Row.new(data: row_data, team: user.team) }
  end

  def process!(patient_session:)
    parse_rows! if rows.nil?
    return if invalid?

    ActiveRecord::Base.transaction do
      rows
        .map(&:to_location)
        .uniq(&:urn)
        .reject(&:invalid?)
        .each do |location|
          location.imported_from = self
          location.save!
        end

      rows
        .map(&:to_vaccination_record)
        .each do |record|
          record.user = user
          record.imported_from = self
          record.patient_session = patient_session
          record.save!
        end
    end
  end

  class Row
    include ActiveModel::Model

    validates :administered, inclusion: [true, false]
    validates :delivery_method, presence: true, if: :administered
    validates :delivery_site, presence: true, if: :administered
    validates :organisation_code,
              presence: true,
              length: {
                maximum: 5
              },
              comparison: {
                equal_to: :valid_ods_code
              }
    validates :recorded_at, presence: true

    def initialize(data:, team:)
      @data = data
      @team = team
    end

    def to_location
      return unless valid?

      Location.new(
        name: @data["SCHOOL_NAME"].strip,
        urn: @data["SCHOOL_URN"].strip
      )
    end

    def to_vaccination_record
      return unless valid?

      VaccinationRecord.new(
        administered:,
        delivery_site:,
        delivery_method:,
        recorded_at:
      )
    end

    def administered
      vaccinated = @data["VACCINATED"]&.downcase

      if vaccinated == "yes"
        true
      elsif vaccinated == "no"
        false
      end
    end

    DELIVERY_SITES = {
      "left thigh" => :left_thigh,
      "right thigh" => :right_thigh,
      "left upper arm" => :left_arm_upper_position,
      "right upper arm" => :right_arm_upper_position,
      "left buttock" => :left_buttock,
      "right buttock" => :right_buttock,
      "nasal" => :nose
    }.freeze

    def delivery_site
      DELIVERY_SITES[@data["ANATOMICAL_SITE"]&.downcase]
    end

    def delivery_method
      return unless delivery_site

      if delivery_site == :nose
        :nasal_spray
      else
        :intramuscular
      end
    end

    def organisation_code
      @data["ORGANISATION_CODE"]
    end

    def recorded_at
      Time.zone.now
    end

    private

    def valid_ods_code
      @team.ods_code
    end
  end

  private

  def csv_is_valid
    return unless csv_is_malformed

    errors.add(:csv, :invalid)
  end

  def csv_has_records
    return unless data

    errors.add(:csv, :empty) if data.empty?
  end

  def headers_are_valid
    return unless data

    missing_headers = EXPECTED_HEADERS - data.headers
    errors.add(:csv, :missing_headers, missing_headers:) if missing_headers.any?
  end

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      next if row.valid?

      # Row 0 is the header row, but humans would call it Row 1. That's also
      # what it would be shown as in Excel. The first row of data is Row 2.
      errors.add("row_#{index + 2}".to_sym, row.errors.full_messages)
    end
  end
end
