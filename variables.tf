variable "cluster-name" {
  description = "Nome do cluster"
}
variable "service-name" {
  type = "map"
  description = "service names"
}
variable "service-port" {
  type = "map"
}
variable "dns-service" {
  type = "map"
}
variable "health" {
  type = "map"
}
variable "region" {
  description = "Região aws stack"
}

variable "subnet-cluster" {
  type = "list"
}
variable "subnet-node" {
  type = "list"
}
variable "vpc-id" {
  
}
variable "internal" {
  
}


