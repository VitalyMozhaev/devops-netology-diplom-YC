# 2. Развертывание кластера на YC

## Требования:

Подготовлена локальная машина (Linux) и [развёрнута облачная инфраструктура](https://gitlab.com/VitalyMozhaev/terraform) (3 ВМ):

  * мастер нода Control Plane node (`cp`)
  * две рабочие ноды (`node1` и `node2`)
  * получены публичные IPv4 адреса всех 3-х инстансов

## Подготовка локальной машины:

Устанавливаем необходимые пакеты:
```bash
sudo apt install apt-transport-https ca-certificates curl -y
# Проверяем python
python3 --version
# Устанавливаем pip3
sudo apt install python3-pip -y
# Устанавливаем git
sudo apt install git -y
```

Копируем проект из github и переходим в каталог kubespray:
```bash
cd ~
git clone https://github.com/kubernetes-sigs/kubespray
cd ~/kubespray/
```

Устанавливаем зависимости:
```bash
# Доустанавливаем нужные пакеты
sudo apt-get install libssl-dev libffi-dev python-dev -y
```

При выполнении команды `sudo pip3 install -r requirements.txt` возникла проблема:

`Could not find a version that satisfies the requirement ansible==5.7.1 (from -r requirements.txt (line 1)) ... No matching distribution found for ansible==5.7.1 (from -r requirements.txt (line 1))`

Решение:
```bash
# На последней версии не получилось установить зависимости,
# пришлось перейти на более раннюю версию, например v2.18.2
git checkout v2.18.1

# Устанавливаем зависимости
sudo pip3 install -r requirements.txt
```

Создаём из примера свой inventory с названием k8s_cluster:
```bash
cp -rfp inventory/sample inventory/k8s_cluster
```

## Конфигурируем с запуском билдера.
Подготовим список IP адресов (cp, node1 и node2) и скопируем их через пробел в первую команду:
```bash
declare -a IPS=(178.154.223.46 51.250.111.254 51.250.35.102)
CONFIG_FILE=inventory/k8s_cluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

Правим полученный предыдущей командой файл `~/kubespray/inventory/k8s_cluster/hosts.yaml`
```bash
all:
  hosts:
    cp1:
      ansible_host: 178.154.223.46
      ip: 10.10.1.6
    node1:
      ansible_host: 51.250.111.254
      ip: 10.10.2.5
    node2:
      ansible_host: 51.250.35.102
      ip: 10.10.3.6
  children:
    kube_control_plane:
      hosts:
        cp1:
    kube_node:
      hosts:
        node1:
        node2:
    etcd:
      hosts:
        cp1:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}

```

---

## Организуем доступ к нодам

В моём случае не нужно создавать и загружать ssh ключ, т.к. для ssh ключ уже добавлен на ноды в момент создания Terraform.

Создаём ssh ключи на локальной машине (в моём случае на локальной виртуалке, с которой производится установка) выполняем:
```bash
#ssh-keygen
```

Копируем созданный публичный ключ с виртуалки, с которой производится установка, на ноды:
```bash
#cat ~/.ssh/id_rsa.pub | ssh dpuser@178.154.223.46 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
#cat ~/.ssh/id_rsa.pub | ssh dpuser@51.250.111.254 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
#cat ~/.ssh/id_rsa.pub | ssh dpuser@51.250.35.102 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

---

## Прописываем параметры

Прописываем пользователя для доступа к нодам в начале файла `~/kubespray/inventory/k8s_cluster/group_vars/all/all.yml`
```
---
ansible_user: dpuser
...
```

Для установки на Debian 10 исправил в файле `~/kubespray/roles/kubernetes/preinstall/vars/debian.yml`
```
required_pkgs:
  - python3-apt
```

Containerd должен быть прописан в файле `~/kubespray/inventory/k8s_cluster/group_vars/k8s_cluster/k8s_cluster.yml`
```
container_manager: containerd
# В некоторых релизах Kubespray прописан по-умолчанию
```

```
# ~/kubespray/inventory/k8s_cluster/group_vars/k8s_cluster/k8s_cluster.yml
# Меняем
#container_manager: docker
на
container_manager: containerd
```

Так же etcd должен запускаться на хосте:
```
# ~/kubespray/inventory/k8s_cluster/group_vars/etcd.yml
# Меняем
etcd_deployment_type: docker
на
etcd_deployment_type: host
```

## Доступ к кластеру

Для доступа к кластеру извне нужно добавить параметр `supplementary_addresses_in_ssl_keys: [51.250.42.98]` в файл `inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`
Заново запустить установку кластера. После этого кластер будет доступен извне.

## Запускаем установку:
```bash
ansible-playbook -i inventory/k8s_cluster/hosts.yaml cluster.yml -b -v --become-user=root
```

Встретился с проблемой:
```bash
TASK [bootstrap-os : Fetch /etc/os-release] ************************************
fatal: [cp1]: FAILED! => {"msg": "Timeout (12s) waiting for privilege escalation prompt: "}
fatal: [node1]: FAILED! => {"msg": "Timeout (12s) waiting for privilege escalation prompt: "}
```

Оказалось, имя виртуальной машины не соответствовало и команда повышения прав sudo выводила ошибку:
```bash
sudo: unable to resolve host cp1
sudo: unable to resolve host node1
```

Пришлось прописать имя на каждой машине
```bash
ssh dpuser@178.154.223.46 "echo '127.0.1.1 cp1' | sudo tee -a /etc/hosts"
ssh dpuser@51.250.111.254 "echo '127.0.1.1 node1' | sudo tee -a /etc/hosts"
ssh dpuser@51.250.35.102 "echo '127.0.1.1 node2' | sudo tee -a /etc/hosts"

```

Результат выполнения:
```bash
...
# Длинный вывод результатов работы ansible, в итоге:
...
PLAY RECAP *********************************************************************
cp1                        : ok=685  changed=137  unreachable=0    failed=0    skipped=1204 rescued=0    ignored=3
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node1                      : ok=491  changed=86   unreachable=0    failed=0    skipped=703  rescued=0    ignored=1
node2                      : ok=491  changed=86   unreachable=0    failed=0    skipped=701  rescued=0    ignored=1
```

## На локальной машине

Устанавливаем kubectl:
```
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

Копируем ~/.kube/config
```bash
mkdir -p ~/.kube && ssh dpuser@178.154.223.46 "sudo cat /root/.kube/config" >> ~/.kube/config
```

Проверяем работу кластера:
```bash
kubectl get nodes
NAME    STATUS   ROLES                  AGE     VERSION
cp1     Ready    control-plane,master   7h22m   v1.22.8
node1   Ready    <none>                 7h20m   v1.22.8
node2   Ready    <none>                 7h20m   v1.22.8

kubectl get pods --all-namespaces
NAMESPACE       NAME                                      READY   STATUS    RESTARTS        AGE
ingress-nginx   ingress-nginx-controller-2hf7k            1/1     Running   0               7h20m
ingress-nginx   ingress-nginx-controller-gxxzs            1/1     Running   0               7h20m
kube-system     calico-kube-controllers-5788f6558-pwgkl   1/1     Running   0               7h20m
kube-system     calico-node-5gkbb                         1/1     Running   0               7h20m
kube-system     calico-node-lbfls                         1/1     Running   0               7h20m
kube-system     calico-node-x92r6                         1/1     Running   0               7h20m
kube-system     coredns-8474476ff8-2ckps                  1/1     Running   0               7h19m
kube-system     coredns-8474476ff8-mkhl9                  1/1     Running   0               7h19m
kube-system     dns-autoscaler-5ffdc7f89d-xs8f5           1/1     Running   0               7h19m
kube-system     kube-apiserver-cp1                        1/1     Running   1               7h22m
kube-system     kube-controller-manager-cp1               1/1     Running   2 (7h19m ago)   7h22m
kube-system     kube-proxy-5xlpd                          1/1     Running   0               174m
kube-system     kube-proxy-8mktf                          1/1     Running   0               174m
kube-system     kube-proxy-jwqcz                          1/1     Running   0               174m
kube-system     kube-scheduler-cp1                        1/1     Running   2 (7h19m ago)   7h22m
kube-system     nginx-proxy-node1                         1/1     Running   0               7h21m
kube-system     nginx-proxy-node2                         1/1     Running   0               7h21m
kube-system     nodelocaldns-2g755                        1/1     Running   0               7h19m
kube-system     nodelocaldns-7krx2                        1/1     Running   0               7h19m
kube-system     nodelocaldns-xngq2                        1/1     Running   0               7h19m

```

## Заметки

Пробрасываем порт (иначе ругается, что сертификаты внутри K8S не поддерживают IP адрес локальной машины, с которой вызываются команды kubectl)
```
ssh -L 6443:127.0.0.1:6443 dpuser@178.154.223.46
```

После перезагрузки виртуалок необходимо обновить файл `hosts`:
```text
# Ansible inventory hosts BEGIN
10.10.1.7 cp1.cluster.local cp1
10.10.2.11 node1.cluster.local node1
10.10.3.13 node2.cluster.local node2
# Ansible inventory hosts END
```
