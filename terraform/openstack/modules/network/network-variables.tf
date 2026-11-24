# ===============================
# Required variables
# ===============================
variable "external_network_id" {
  description = "ID of the external network to connect to, used to access the internet"
  type        = string
}
variable "subnet_cidr" {
  description = "CIDR of the subnet of the subnet. Meaning the range of IP addresses that will be available for the instances in the subnet."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "Must be a valid ip address with mask"
  }
}
# variable "server_ports" {
#   description = "List of ports the server uses and accepts connections to"
#   type        = set(string)

#   validation {
#     condition     = length(var.server_ports) > 0
#     error_message = "At least one port must be specified"
#   }

#   validation {
#     condition     = alltrue([for port in var.server_ports : port >= 20 && port <= 65535])
#     error_message = "Ports must be between 20 and 65535"
#   }
# }
variable "wireguard_port" {
  description = "Port to use for the wireguard VPN"
  type        = number
  default     = 51820
  validation {
    condition     = var.wireguard_port >= 80 && var.wireguard_port <= 65535
    error_message = "The wireguard port must be between 80 and 65535"
  }
}
