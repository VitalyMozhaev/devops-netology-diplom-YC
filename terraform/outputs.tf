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
output "access_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}
output "secret_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}
