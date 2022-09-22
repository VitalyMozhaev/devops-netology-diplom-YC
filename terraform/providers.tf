# Provider

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

# Service account

# Create SA
resource "yandex_iam_service_account" "dp-sa" {
  folder_id = var.folder_id
  name      = "dp-sa"
}

# Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.dp-sa.id}"
}

# Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.dp-sa.id
  description        = "static access key for object storage"
}

# Bucket

# Use keys to create bucket
resource "yandex_storage_bucket" "dp-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "dp-bucket"
}
