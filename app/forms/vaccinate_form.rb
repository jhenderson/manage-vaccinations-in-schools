# frozen_string_literal: true

class VaccinateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :programme, :current_user, :todays_batch

  attribute :knows_vaccination, :boolean
  attribute :not_already_had, :boolean
  attribute :feeling_well, :boolean
  attribute :no_allergies, :boolean
  attribute :not_taking_medication, :boolean
  attribute :not_pregnant, :boolean
  attribute :pre_screening_notes, :string

  attribute :administered, :boolean
  attribute :delivery_method, :string
  attribute :delivery_site, :string
  attribute :dose_sequence, :integer
  attribute :vaccine_id, :integer

  validates :administered, inclusion: [true, false]

  with_options if: :administered do
    validates :knows_vaccination, presence: true
    validates :not_already_had, presence: true
    validates :no_allergies, presence: true
  end

  with_options if: -> { administered && ask_not_taking_medication? } do
    validates :not_taking_medication, presence: true
  end

  with_options if: -> { administered && ask_not_pregnant? } do
    validates :not_pregnant, presence: true
  end

  with_options if: :administered do
    validates :delivery_method, presence: true
    validates :delivery_site, presence: true
    validates :vaccine_id, presence: true
  end

  def save(draft_vaccination_record:)
    return nil if invalid?

    return false unless pre_screening.save

    draft_vaccination_record.reset!

    if administered
      draft_vaccination_record.outcome = "administered"

      if delivery_site != "other"
        draft_vaccination_record.delivery_method = delivery_method
        draft_vaccination_record.delivery_site = delivery_site
      end
    end

    draft_vaccination_record.batch_id = todays_batch&.id
    draft_vaccination_record.dose_sequence = dose_sequence
    draft_vaccination_record.patient_id = patient_session.patient_id
    draft_vaccination_record.performed_at = Time.current
    draft_vaccination_record.performed_by_user = current_user
    draft_vaccination_record.performed_ods_code = organisation.ods_code
    draft_vaccination_record.programme = programme
    draft_vaccination_record.session_id = patient_session.session_id
    draft_vaccination_record.vaccine_id = vaccine_id

    draft_vaccination_record.save # rubocop:disable Rails/SaveBang
  end

  def ask_not_taking_medication?
    programme.doubles?
  end

  def ask_not_pregnant?
    programme.hpv? || programme.td_ipv?
  end

  private

  delegate :organisation, to: :patient_session

  def pre_screening
    @pre_screening ||=
      patient_session.pre_screenings.build(
        feeling_well: feeling_well || false,
        knows_vaccination: knows_vaccination || false,
        no_allergies: no_allergies || false,
        not_already_had: not_already_had || false,
        not_pregnant: not_pregnant || false,
        not_taking_medication: not_taking_medication || false,
        notes: pre_screening_notes,
        performed_by: current_user,
        programme:,
        session_date_id:
      )
  end

  def session_date_id
    patient_session.session.session_dates.today.first&.id
  end
end
