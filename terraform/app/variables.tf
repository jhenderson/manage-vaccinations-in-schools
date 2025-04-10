variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "String literal for the environment"
  nullable    = false

  validation {
    condition = contains([
      "poc", "copilotmigration", "qa", "test", "training", "preview", "production"
    ], var.environment)
    error_message = "Valid values for environment: poc, copilotmigration, qa, test, training, preview, production."
  }
}

variable "access_logs_bucket" {
  type        = string
  default     = "nhse-mavis-access-logs"
  description = "Name of the S3 bucket which stores access logs for various resources"
}

variable "appspec_bucket" {
  type        = string
  description = "Name of the S3 bucket which stores appspec files"
  nullable    = false
}

variable "account_id" {
  type        = string
  default     = "393416225559"
  description = "ID of aws account. Defaults to non-prod account."
  nullable    = false
}

variable "zone_name" {
  type        = string
  default     = "mavistesting.com"
  description = "Domain for which to create DNS certificate"
  nullable    = false
}

variable "http_hosts" {
  type = object({
    MAVIS__HOST                        = string
    MAVIS__GIVE_OR_REFUSE_CONSENT_HOST = string
  })
  description = "Http host names. Only requests that set the HTTP Host Header to one of these values will be accepted."
  nullable    = true
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "The name of the SSL Policy for the https listener"
  nullable    = false
}

locals {
  unique_host_headers = toset(values(var.http_hosts))
  host_headers        = tolist(local.unique_host_headers)
}

variable "dns_certificate_arn" {
  type        = list(string)
  description = "The ARN(s) for pre-existing DNS certificate(s) to be used for https listener"
}

locals {
  default_certificate_arn     = var.dns_certificate_arn == null ? module.dns_route53[0].certificate_arn : var.dns_certificate_arn[0]
  additional_sni_certificates = var.dns_certificate_arn == null ? [] : slice(var.dns_certificate_arn, 1, length(var.dns_certificate_arn))
}

variable "resource_name" {
  type = object(
    {
      dbsubnet_group           = string
      db_cluster               = string
      db_instance              = string
      rds_security_group       = string
      loadbalancer             = string
      lb_security_group        = string
      cloudwatch_vpc_log_group = string
    }
  )
  description = "Names of terraform managed resource. Used to import pre-existing infrastructure resources"
  nullable    = false
}

variable "ecs_log_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain logs for ecs instances"
  nullable    = false
}
variable "vpc_log_retention_days" {
  type        = number
  default     = 14
  description = "Number of days to retain logs for the vpc traffic"
  nullable    = false
}

########## Task definition configuration ##########

variable "rails_env" {
  type        = string
  default     = "staging"
  description = "The rails environment configuration to use for the mavis application"
  nullable    = false
  validation {
    condition     = contains(["staging", "production"], var.rails_env)
    error_message = "Incorrect rails environment, allowed values are: {staging, production}"
  }
}

variable "rails_master_key_path" {
  type        = string
  default     = "/mavis/development/credentials/RAILS_MASTER_KEY"
  description = "The path of the System Manager Parameter Store secure string for the rails master key."
  nullable    = false
}

variable "docker_image" {
  type        = string
  default     = "mavis/webapp"
  description = "The docker image name for the essential container in the task definition"
  nullable    = false
}

variable "image_digest" {
  type        = string
  description = "The docker image digest for the essential container in the task definition."
  nullable    = false
}

variable "enable_cis2" {
  type        = bool
  default     = true
  description = "Boolean toggle to determine whether the CIS2 feature should be enabled."
  nullable    = false
}

variable "enable_pds_enqueue_bulk_updates" {
  type        = bool
  default     = false
  description = "Whether PDS jobs that update patients in bulk should execute or not. This is disabled in non-production environments to avoid making unnecessary requests to PDS."
  nullable    = false
}

variable "enable_splunk" {
  type        = bool
  default     = true
  description = "Boolean toggle to determine whether the Splunk feature should be enabled."
  nullable    = false
}

locals {
  is_production = var.environment == "production"

  task_envs = [
    {
      name  = "DB_HOST"
      value = aws_rds_cluster.aurora_cluster.endpoint
    },
    {
      name  = "DB_NAME"
      value = aws_rds_cluster.aurora_cluster.database_name
    },
    {
      name  = "RAILS_ENV"
      value = var.rails_env
    },
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "MAVIS__HOST"
      value = var.http_hosts.MAVIS__HOST
    },
    {
      name  = "MAVIS__GIVE_OR_REFUSE_CONSENT_HOST"
      value = var.http_hosts.MAVIS__GIVE_OR_REFUSE_CONSENT_HOST
    },
    {
      name  = "MAVIS__CIS2__ENABLED"
      value = var.enable_cis2 ? "true" : "false"
    },
    {
      name  = "MAVIS__PDS__ENQUEUE_BULK_UPDATES"
      value = var.enable_pds_enqueue_bulk_updates ? "true" : "false"
    },
    {
      name  = "MAVIS__SPLUNK__ENABLED"
      value = var.enable_splunk ? "true" : "false"
    }
  ]
  task_secrets = [
    {
      name      = var.db_secret_arn == null ? "DB_CREDENTIALS" : "DB_SECRET"
      valueFrom = var.db_secret_arn == null ? aws_rds_cluster.aurora_cluster.master_user_secret[0].secret_arn : var.db_secret_arn
    },
    {
      name      = "RAILS_MASTER_KEY"
      valueFrom = var.rails_master_key_path
    },
    {
      name      = "MAVIS__PDS__WAIT_BETWEEN_JOBS",
      valueFrom = aws_ssm_parameter.pds_wait_between_jobs.name,
    },
    {
      name      = "GOOD_JOB_MAX_THREADS",
      valueFrom = aws_ssm_parameter.good_job_max_threads.name,
    },
  ]
}

########## RDS configuration ##########

variable "db_secret_arn" {
  type        = string
  description = "The ARN of the secret containing the DB credentials."
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "The number of days to retain backups for the RDS cluster."
}

########## ESC/Scaling Configuration ##########
variable "enable_autoscaling" {
  type        = bool
  default     = false
  description = "Boolean toggle to determine whether the ECS service should have autoscaling enabled."
}

variable "minimum_web_replicas" {
  type        = number
  default     = 3
  description = "Minimum amount of allowed replicas for web service"
}

variable "maximum_web_replicas" {
  type        = number
  default     = 3
  description = "Maximum amount of allowed replicas for web service"
}

variable "minimum_good_job_replicas" {
  type        = number
  default     = 2
  description = "Minimum amount of allowed replicas for good-job service"
}

variable "active_lb_target_group" {
  type        = string
  description = "The actual loadbalancer target group is set by Codedeploy. However in scenarios where new resources behind the load balancer are created, terraform already needs to know the current target group. In this case, set the variable to the currently active target group."
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_lb_target_group)
    error_message = "Valid target groups: blue, green"
  }
}

locals {
  ecs_initial_lb_target_group = var.active_lb_target_group == "green" ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
  ecs_sg_ids                  = [module.web_service.security_group_id, module.good_job_service.security_group_id]
}
