# outputs

output "cp-internal-ip" {
  value = yandex_compute_instance.cp.network_interface.0.ip_address
}

output "cp-external-ip" {
  value = yandex_compute_instance.cp.network_interface.0.nat_ip_address
}

output "node1-internal-ip" {
  value = yandex_compute_instance.node1.network_interface.0.ip_address
}

output "node1-external-ip" {
  value = yandex_compute_instance.node1.network_interface.0.nat_ip_address
}

output "node2-internal-ip" {
  value = yandex_compute_instance.node2.network_interface.0.ip_address
}

output "node2-external-ip" {
  value = yandex_compute_instance.node2.network_interface.0.nat_ip_address
}
