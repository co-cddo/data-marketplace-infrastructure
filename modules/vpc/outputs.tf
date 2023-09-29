output "private_subnets_output" {
    value = aws_subnet.private_subnets.*.id
}
output "public_subnets_output" {
    value = aws_subnet.public_subnets.*.id
}

output "vpc" {
    value = aws_vpc.vpc_dm_eks
}