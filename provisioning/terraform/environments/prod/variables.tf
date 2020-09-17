variable "configuration_compute_engine_development_workstation_ssh_public_key_file_name" {
  default     = "development-workstation-ssh-user.pub"
  description = "Name of the public key file to use for the development workstation"
}

variable "configuration_compute_engine_keys_directory_name" {
  default     = "compute-engine"
  description = "Name of the Compute Engine public keys directory"
}

variable "configuration_iot_core_keys_directory_name" {
  default     = "iot-core"
  description = "Name of the IoT Core public keys directory"
}

variable "configuration_iot_core_smart_desk_public_key_file_name" {
  default     = "smart_desk.pem"
  description = "Name of the public key file to use to register the Smart Desk to IoT Core"
}

variable "configuration_public_keys_directory_name" {
  default     = "public-keys"
  description = "Name of the public keys directory"
}

variable "configuration_directory_name" {
  default     = "terraform"
  description = "Name of the Terraform configuration directory"
}

variable "google_default_region" {
  description = "The default Google Cloud region"
}

variable "google_default_zone" {
  description = "The default Google Cloud zone"
}

variable "google_iot_project_id" {
  description = "Google Cloud project ID for the IoT environment"
}

variable "google_billing_account_id" {
  description = "The default billing account for Google Cloud projects"
}

variable "google_iac_project_id" {
  description = "Google Cloud project ID for the IaC pipeline"
}

variable "development_workstation_machine_type" {
  default     = "n2-standard-8"
  description = "Machine type for development workstations"
}

variable "development_workstation_min_cpu_platform" {
  default     = "Intel Cascade Lake"
  description = "Minimum CPU platform required for development workstations"
}

variable "development_workstation_name" {
  default     = "dev-linux-1"
  description = "Name of the development workstation"
}

variable "development_workstation_ssh_user" {
  description = "Username of the user to connect to the development workstation via SSH"
}

variable "google_organization_id" {}
