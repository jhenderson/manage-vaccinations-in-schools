# frozen_string_literal: true

require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.good_job.enable_cron = true
  config.good_job.cron = {
    mesh_validate_mailbox: {
      cron: "every day at 1am",
      class: "MESHValidateMailboxJob",
      description: "Validate MESH mailbox"
    },
    mesh_dps_export: {
      cron: "every day at 2am",
      class: "MESHDPSExportJob",
      description: "Export DPS data via MESH"
    }
  }
end
