variable "subscription_id" {
  description = "Explicit subscription to provision; do not rely on the CLI default."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "Provide the Azure subscription UUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant containing the subscription."
  type        = string
}

variable "operator_object_id" {
  description = "Stable Entra object ID of the human bootstrap operator."
  type        = string
}

variable "location" {
  description = "Azure region for state storage."
  type        = string
  default     = "uksouth"
}

variable "name_prefix" {
  description = "Short lab identifier used in globally unique storage naming."
  type        = string
  default     = "butler"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,9}$", var.name_prefix))
    error_message = "Use 3–10 lowercase letters/digits, starting with a letter."
  }
}

variable "expires_on" {
  description = "Planned lab teardown date (YYYY-MM-DD); a tag, not automatic deletion."
  type        = string

  validation {
    condition     = can(formatdate("YYYY-MM-DD", "${var.expires_on}T00:00:00Z"))
    error_message = "Use a valid date in YYYY-MM-DD form."
  }
}

variable "monthly_budget_amount" {
  description = "Monthly alert budget in the subscription's billing currency; not a spending cap."
  type        = number
  default     = 20

  validation {
    condition     = var.monthly_budget_amount > 0
    error_message = "The budget must be greater than zero."
  }
}

variable "budget_start_date" {
  description = "First day of the current month when initially applying (YYYY-MM-01); keep stable afterwards."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01$", var.budget_start_date)) && can(formatdate("YYYY-MM-DD", "${var.budget_start_date}T00:00:00Z"))
    error_message = "Use a valid first-of-month date, e.g. 2026-09-01."
  }
}

variable "budget_contact_emails" {
  description = "Optional additional alert recipients; subscription Owners are always notified."
  type        = list(string)
  default     = []
}
