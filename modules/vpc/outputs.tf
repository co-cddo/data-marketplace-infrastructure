output "private_subnets_output" {
  value = aws_subnet.private_subnets.*.id
}
output "public_subnets_output" {
  value = aws_subnet.public_subnets.*.id
}
output "vpc" {
  value = aws_vpc.vpc_dm_eks
}
output "vpc_peering" {
  value = aws_vpc_peering_connection.peer
}
output "vpc_peering_route_default_to_new" {
  value = aws_route.default_to_new
}
output "vpc_peering_route_new_to_default" {
  value = aws_route.new_to_default
}
