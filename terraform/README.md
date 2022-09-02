# 1. Создание облачной инфраструктуры на YC

## Подготовка локальной машины:
```bash
# Создаём каталог
mkdir -p /home/dpuser/terraform/1.1.9/
cd /home/dpuser/terraform/1.1.9/

# Загружаем архив
wget https://hashicorp-releases.website.yandexcloud.net/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip

# Распаковываем
sudo unzip terraform_1.1.9_linux_amd64.zip -d /usr/bin
Archive:  terraform_1.1.9_linux_amd64.zip
  inflating: /usr/bin/terraform

# Проверяем
terraform -v
Terraform v1.1.9
on linux_amd64
```

Создаём файл конфигурации Terraform CLI (~/.terraformrc):
```bash
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

Далее создаём рабочую директорию и переходим в неё:
```bash
mkdir ~/cloud-terraform
cd ~/cloud-terraform/
```

Создаём файлы terraform:

https://github.com/VitalyMozhaev/devops-netology-diplom-YC/tree/main/terraform


