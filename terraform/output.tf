output "app_subnet_a_id" {
  value = aws_subnet.app_a.id
}

output "app_subnet_b_id" {
  value = aws_subnet.app_b.id
}

output "mgmt_subnet_id" {
  value = aws_subnet.mgmt.id
}

output "backend_subnet_id" {
  value = aws_subnet.backend.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}
