variable "tags" {
  description = "Tags to apply to resources"
  type        = map(any)
  default = {
    Environment = "AWS-recording-ingest-transform"
  }
}