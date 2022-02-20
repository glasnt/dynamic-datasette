variable "project" {
  type        = string
  description = "Google Cloud Platform Project ID"
}

variable "region" {
  type    = string
  description = "Google Cloud Platform Region"
  default = "us-central1"
}