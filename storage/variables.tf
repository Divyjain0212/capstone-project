variable "bucket_name" {
    type = string
    default = "terraform-state-divy-bucket"
}

variable "dynamodb_table" {
    type = string
    default = "terraform-lock-table"
}

variable "env"{
    type = string
    default = "dev"
}