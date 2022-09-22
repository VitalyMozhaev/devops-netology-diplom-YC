terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.75.0"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "dp-bucket"
    region     = "ru-central1-a"
    key        = "terraform.tfstate.d/stage/terraform.tfstate"
    access_key = "YC...oJ"
    secret_key = "YCO...R8F"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
