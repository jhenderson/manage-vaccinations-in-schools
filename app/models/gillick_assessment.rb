# frozen_string_literal: true

# == Schema Information
#
# Table name: gillick_assessments
#
#  id                   :bigint           not null, primary key
#  knows_consequences   :boolean          not null
#  knows_delivery       :boolean          not null
#  knows_disease        :boolean          not null
#  knows_side_effects   :boolean          not null
#  knows_vaccination    :boolean          not null
#  notes                :text             default(""), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_gillick_assessments_on_patient_session_id    (patient_session_id) UNIQUE
#  index_gillick_assessments_on_performed_by_user_id  (performed_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class GillickAssessment < ApplicationRecord
  include LocationNameConcern
  include Recordable
  include WizardStepConcern

  audited

  belongs_to :patient_session
  belongs_to :assessor, class_name: "User", foreign_key: :assessor_user_id

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session
  has_one :location, through: :session

  encrypts :notes

  on_wizard_step :gillick do
    validates :gillick_competent, inclusion: { in: [true, false] }
  end

  on_wizard_step :location, exact: true do
    validates :location_name, presence: true
  end

  on_wizard_step :notes do
    validates :notes, length: { maximum: 1000 }, presence: true
  end

  def wizard_steps
    [:gillick, (:location if requires_location_name?), :notes, :confirm].compact
  end
end
