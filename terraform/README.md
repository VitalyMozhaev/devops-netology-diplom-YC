# 1. Создание облачной инфраструктуры на YC

Для разворачивания Kubernetes кластера нам потребуется 3 инстанса: мастер нода (Control Plane node - `cp`) и две рабочие ноды (`node1` и `node2`).

## Подготовка локальной машины:
```bash
# Создаём пользователя
sudo adduser dpuser
# Добавляем в группу sudo
sudo usermod -aG sudo dpuser
# Заходим под пользователем
# su - dpuser

sudo apt install mc -y

# Создаём каталог
mkdir -p /home/dpuser/terraform/1.2.9/ && cd /home/dpuser/terraform/1.2.9/

# Загружаем архив
wget https://hashicorp-releases.yandexcloud.net/terraform/1.2.9/terraform_1.2.9_linux_amd64.zip

# Распаковываем
sudo unzip terraform_1.2.9_linux_amd64.zip -d /usr/bin
Archive:  terraform_1.2.9_linux_amd64.zip
  inflating: /usr/bin/terraform

# Проверяем
terraform -v
Terraform v1.2.9
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
mkdir ~/yc-terraform && cd ~/yc-terraform/
```

Создаём рабочее пространство (workspace):
```bash
terraform workspace new stage
Created and switched to workspace "stage"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

Проверяем список workspace:
```bash
terraform workspace list
  default
* stage
```

При необходимости, переключаемся на нужный workspace:
```bash
terraform workspace select stage
Switched to workspace "stage".mc
```

Создаём файлы terraform:

- [main.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/main.tf)
- [meta.txt](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/meta.txt)
- [networks.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/networks.tf)
- [outputs.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/outputs.tf)
- [providers.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/providers.tf)
- [variables.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/variables.tf)
- [versions.tf](https://gitlab.com/VitalyMozhaev/terraform/-/blob/main/versions.tf)

При первоv запуске в файле `versions.tf` не должно быть блока:
```text
backend "s3" {
  ...
}
```
Его мы добавим позже, когда создадим сам bucket.

Для получения и сохранения `access_key` и `secret_key` пропишем файле `outputs.tf`:
```text
output "access_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}
output "secret_key" {
  value = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}
```
Это позволит сохранить значения `access_key` и `secret_key` в в нашем локальном файле state.

Выполняем первый запуск:
```bash
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.75.0"...
- Installing yandex-cloud/yandex v0.75.0...
- Installed yandex-cloud/yandex v0.75.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Проверяем конфигурацию:
```bash
terraform validate
Success! The configuration is valid.
```

После проверки конфигурации выполняем команду `terraform plan`

В терминале будет выведен список ресурсов с параметрами. Это проверочный этап: ресурсы не будут созданы. Если в конфигурации есть ошибки, Terraform на них укажет.
```bash
terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.cp will be created
  + resource "yandex_compute_instance" "cp" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      ...
      
    }

  # yandex_compute_instance.node1 will be created
  + resource "yandex_compute_instance" "node1" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      ...
      
    }

  # yandex_compute_instance.node2 will be created
  + resource "yandex_compute_instance" "node2" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      ...

    }

  # yandex_dp_service_account.dp-sa will be created
  + resource "yandex_dp_service_account" "dp-sa" {
      + created_at = (known after apply)
      + folder_id  = "b1gjtpmttvjdjbioe6ak"
      + id         = (known after apply)
      + name       = "dp-sa"
    }

  # yandex_dp_service_account_static_access_key.sa-static-key will be created
  + resource "yandex_dp_service_account_static_access_key" "sa-static-key" {
      + access_key           = (known after apply)
      + created_at           = (known after apply)
      + description          = "static access key for object storage"
      + encrypted_secret_key = (known after apply)
      + id                   = (known after apply)
      + key_fingerprint      = (known after apply)
      + secret_key           = (sensitive value)
      + service_account_id   = (known after apply)
    }

  # yandex_resourcemanager_folder_dp_member.sa-editor will be created
  + resource "yandex_resourcemanager_folder_dp_member" "sa-editor" {
      + folder_id = "b1gjtpmttvjdjbioe6ak"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "storage.editor"
    }

  # yandex_storage_bucket.dp-bucket will be created
  + resource "yandex_storage_bucket" "dp-bucket" {
      + access_key            = (known after apply)
      + acl                   = "private"
      + bucket                = "dp-bucket"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = (known after apply)
          + read = (known after apply)
        }

      + versioning {
          + enabled = (known after apply)
        }
    }

  # yandex_vpc_network.netology-diplom will be created
  + resource "yandex_vpc_network" "netology-diplom" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "netology-diplom"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet-a will be created
  + resource "yandex_vpc_subnet" "subnet-a" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet-b will be created
  + resource "yandex_vpc_subnet" "subnet-b" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet-c will be created
  + resource "yandex_vpc_subnet" "subnet-c" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-c"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-c"
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cp-external-ip    = (known after apply)
  + cp-internal-ip    = (known after apply)
  + node1-external-ip = (known after apply)
  + node1-internal-ip = (known after apply)
  + node2-external-ip = (known after apply)
  + node2-internal-ip = (known after apply)

```

Чтобы создать ресурсы выполняем команду:
```bash
terraform apply
...
# Длинный вывод этапов создания ресурсов, в итоге:
...
yandex_compute_instance.node1: Creation complete after 27s [id=epdlcbsmss07ldc1p23v]
yandex_compute_instance.cp: Creation complete after 28s [id=fhmdq8f8aoag4bg3q3bj]
yandex_compute_instance.node2: Creation complete after 32s [id=ef3d8vj67nek7d05ccvu]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

access_key = <sensitive>
cp-external-ip = "178.154.223.46"
cp-internal-ip = "10.10.1.7"
node1-external-ip = "51.250.111.254"
node1-internal-ip = "10.10.2.11"
node2-external-ip = "51.250.35.102"
node2-internal-ip = "10.10.3.13"
secret_key = <sensitive>
```

## Настройка миграции файла состояния на S3

В файле `versions.tf` прописываем:
```text
terraform {
  ...
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
```

Затем выполняем `terraform init`.
Система снова инициализирует состояние текущего каталога и создаст файл state на удаленном хранилище.
Чтобы убедиться, можно зайти в наше хранилище, а в нем найти файл `terraform.tfstate.d/stage/terraform.tfstate`.
```bash
terraform init
Do you want to migrate all workspaces to "s3"?
...
  Enter a value: yes


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.75.0

Terraform has been successfully initialized!
```

Полученные IP адреса будем использовать для настройки и развёртки Kubernetes

## Возможные проблемы:

1. При запуске `terraform apply`:

`... rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded`

Решение:

`Необходимо удалить все созданные сети и подсети в каталоге YC (или не создавать сети при создании каталога в YC).`


## Заметки:

Чтобы удалить ресурсы:
```bash
terraform destroy
```

Завершить все сессии пользователя:
```bash
sudo pkill -9 -u dpuser
```

## Полезные ссылочки:

- [Terraform - yandex_storage_bucket](https://registry.tfpla.net/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket#enable-logging)

- [Работа с Terraform в yandex облаке](https://sidmid.ru/%D1%80%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%D1%82%D1%8C-%D1%81-terraform-%D0%B2-yandex-%D0%BE%D0%B1%D0%BB%D0%B0%D0%BA%D0%B5/?ysclid=l88mngu9cu345490599)

