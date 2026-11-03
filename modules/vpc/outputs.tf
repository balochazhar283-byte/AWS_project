# =============================================================================
# modules/vpc/outputs.tf
# PURPOSE: The "return values" of the VPC module. Other modules cannot see
# resources inside this module; they can only use what is exported here, and
# only through the root module (module.vpc.<output_name>).
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR range of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets (Lambda lives here)."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets (RDS lives here)."
  value       = aws_subnet.private_db[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.main.id
}
