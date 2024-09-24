# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  def index
    @vaccination_records = vaccination_records.recorded

    render layout: "full"
  end

  def show
    @vaccination_record = vaccination_records.find(params[:id])
    @patient = @vaccination_record.patient
    @session = @vaccination_record.session
  end

  def export_dps
    send_data(dps_export.csv, filename: dps_export.filename)
  end

  def reset_dps_export
    programme.dps_exports.destroy_all

    flash[:success] = {
      heading: "DPS exports have been reset for the programme"
    }

    redirect_to programme_vaccination_records_path(programme)
  end

  private

  def programme
    @programme ||= policy_scope(Programme).find(params[:programme_id])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .includes(
          :batch,
          :immunisation_imports,
          :performed_by_user,
          :programme,
          :vaccine,
          patient: [:school, { parent_relationships: :parent }],
          session: :location
        )
        .where(programme:)
        .order(:recorded_at)
        .strict_loading
  end

  def dps_export
    @dps_export ||= DPSExport.create!(programme:)
  end
end
