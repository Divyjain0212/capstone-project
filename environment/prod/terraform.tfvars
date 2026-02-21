region = "ap-south-1"
dynamodb_table = "prod-terraform-lock-table"
key = "prod/terraform.tfstate"
bucket_name = "prod-terraform-state-divy-bucket"

env = "prod"

key_name = "linux-key"

vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

instance_type = "m7i-flex.large"
asg_min_size = 4
asg_max_size = 10
asg_desired_capacity = 5
port = "3000"

db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_name = "capstonedb"
db_multi_az = true
db_backup_retention_days = 1

sns_email_endpoint = "divyjain07291@gmail.com"
cpu_threshold = 75
memory_threshold = 80
unhealthy_host_threshold = 1
latency_threshold = 500