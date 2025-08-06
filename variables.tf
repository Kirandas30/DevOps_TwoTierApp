variable "aws_region" {
  default = "eu-north-1"
}
variable "key_pair_name" {
  description = "Name of the Key Pair"
  default     = "MyKeyPair"
}

variable "key_pair_path" {
  description = "Path to the Private Key (.pem file)"
  default     = "~/Downloads/MyKeyPair.pem"
}
