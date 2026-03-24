variable "name_prefix" {
  type        = string
  description = "Prefix for Cognito resources."
}

variable "domain_prefix" {
  type        = string
  description = "Globally unique Cognito hosted UI domain prefix (e.g. cct-prod-dash)."
}

variable "callback_urls" {
  type        = list(string)
  description = "OAuth redirect URLs for the dashboard SPA (must include callback.html)."
}

variable "logout_urls" {
  type        = list(string)
  description = "OAuth logout redirect URLs."
}
