# Дипломный практикум в Yandex.Cloud

 Этапы выполнения:
   * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
   * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
   * [Создание тестового приложения](#создание-тестового-приложения)
   * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
   * [Установка и настройка CI/CD](#установка-и-настройка-cicd)

---
## 1. Создание облачной инфраструктуры

Процесс реализации и исходники находятся в [репозитории](https://gitlab.com/VitalyMozhaev/terraform).

Результат выполнения:

Посредством Terraform развёрнута инфраструктура для дальнейшего разворачивания Kubernetes кластера:
- Создана VPC с подсетями в разных зонах доступности.
- Подняты 3 инстанса (Control Plane node и две рабочие ноды) в разных подсетях с разной зоной доступности.

---
## 2. Создание Kubernetes кластера

Процесс реализации и исходники находятся в [репозитории](https://gitlab.com/VitalyMozhaev/k8s).

Результат выполнения:

- На подготовленной инфраструктуре Yandex.Cloud развёрнут Kubernetes кластер.
- Файл конфигураций `~/.kube/config` перенесён на локальную машину для управления удалённым кластером.
- Результат выполнения команды `kubectl get pods --all-namespaces`:
```bash
sudo kubectl get nodes
[sudo] пароль для kubeuser:
NAME    STATUS   ROLES                  AGE   VERSION
cp1     Ready    control-plane,master   13m   v1.23.4
node1   Ready    <none>                 11m   v1.23.4
node2   Ready    <none>                 11m   v1.23.4

kubectl get pods --all-namespaces
NAMESPACE     NAME                                      READY   STATUS    RESTARTS        AGE
kube-system   calico-kube-controllers-5788f6558-6h9zr   1/1     Running   0               5h
kube-system   calico-node-j52bq                         1/1     Running   0               5h
kube-system   calico-node-n8qnd                         1/1     Running   0               5h
kube-system   calico-node-s5zvm                         1/1     Running   0               5h
kube-system   coredns-8474476ff8-lv9n6                  1/1     Running   0               4h59m
kube-system   coredns-8474476ff8-z596m                  1/1     Running   0               4h59m
kube-system   dns-autoscaler-5ffdc7f89d-c47cq           1/1     Running   0               4h59m
kube-system   kube-apiserver-cp1                        1/1     Running   1               5h2m
kube-system   kube-controller-manager-cp1               1/1     Running   2 (4h58m ago)   5h1m
kube-system   kube-proxy-2xmk4                          1/1     Running   0               5h
kube-system   kube-proxy-5f8hv                          1/1     Running   0               5h
kube-system   kube-proxy-5rmbq                          1/1     Running   0               5h
kube-system   kube-scheduler-cp1                        1/1     Running   2 (4h58m ago)   5h2m
kube-system   nginx-proxy-node1                         1/1     Running   0               5h
kube-system   nginx-proxy-node2                         1/1     Running   0               5h
kube-system   nodelocaldns-458ms                        1/1     Running   0               4h59m
kube-system   nodelocaldns-dkthv                        1/1     Running   0               4h59m
kube-system   nodelocaldns-hcvrj                        1/1     Running   0               4h59m
```

---
## 3. Создание тестового приложения

Процесс реализации и исходники находятся в [репозитории](https://gitlab.com/VitalyMozhaev/app).

Результат выполнения:

- [Git репозиторий с тестовым приложением и Dockerfile](https://gitlab.com/VitalyMozhaev/app).
- [Реестр с собранным docker image](https://gitlab.com/VitalyMozhaev/app/container_registry/3434688).


---
## 4. Подготовка cистемы мониторинга и деплой приложения


---
## 5. Установка и настройка CI/CD

