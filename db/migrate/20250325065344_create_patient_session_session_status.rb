# frozen_string_literal: true

class CreatePatientSessionSessionStatus < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :patient_session_session_statuses do |t|
      t.references :patient_session,
                   null: false,
                   index: false,
                   foreign_key: {
                     on_delete: :cascade
                   }
      t.references :programme, null: false, index: false, foreign_key: true
      t.integer :status, null: false, default: 0, index: true
      t.index %i[patient_session_id programme_id], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
