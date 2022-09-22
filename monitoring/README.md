# 4. Подготовка cистемы мониторинга и деплой приложения

## 4.1. Установка и настройка системы мониторинга kube-prometheus

Для установки мониторинга Kubernetes кластера воспользуемся пакетом [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

### Подготовка:

Создаём namespace:
```bash
kubectl create ns stage
namespace/stage created
```

Проверяем пространства имён:
```bash
kubectl get ns
NAME              STATUS   AGE
default           Active   6d19h
kube-node-lease   Active   6d19h
kube-public       Active   6d19h
kube-system       Active   6d19h
stage             Active   49s
```

Переключаемся на пространство имён stage:
```bash
kubectl config set-context --current --namespace=stage
Context "kubernetes-admin@cluster.local" modified.
```

Установка HELM на Linux

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

Для установки Kube-Prometheus-Stack нужно добавить репозитории в helm:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
``` 

### Запускаем установку Kube-Prometheus-Stack
```bash
helm install --namespace stage k8sgraf prometheus-community/kube-prometheus-stack
NAME: k8sgraf
LAST DEPLOYED: Tue Sep 20 12:48:51 2022
NAMESPACE: stage
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace stage get pods -l "release=k8sgraf"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

Для доступа к сервису заменяем тип ClusterIP на LoadBalancer (`type: LoadBalancer`):
```
kubectl edit svc k8sgraf-grafana
Меняю это
  ...
  selector:
    app.kubernetes.io/instance: stable
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}

на это

  ...
  selector:
    app.kubernetes.io/instance: stable
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: LoadBalancer
```

```bash
kubectl get deploy,po,svc
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/k8sgraf-grafana                       1/1     1            1           22m
deployment.apps/k8sgraf-kube-prometheus-st-operator   1/1     1            1           22m
deployment.apps/k8sgraf-kube-state-metrics            1/1     1            1           22m

NAME                                                         READY   STATUS    RESTARTS      AGE
pod/alertmanager-k8sgraf-kube-prometheus-st-alertmanager-0   2/2     Running   1 (22m ago)   22m
pod/k8sgraf-grafana-6f66b4865b-f7942                         3/3     Running   0             22m
pod/k8sgraf-kube-prometheus-st-operator-5dbcb8d7c7-cvz79     1/1     Running   0             22m
pod/k8sgraf-kube-state-metrics-fcc95d54f-zc6nk               1/1     Running   0             22m
pod/k8sgraf-prometheus-node-exporter-5kcxh                   1/1     Running   0             22m
pod/k8sgraf-prometheus-node-exporter-66lb8                   1/1     Running   0             22m
pod/k8sgraf-prometheus-node-exporter-7zsj4                   1/1     Running   0             22m
pod/prometheus-k8sgraf-kube-prometheus-st-prometheus-0       2/2     Running   0             22m

NAME                                              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-operated                     ClusterIP      None            <none>        9093/TCP,9094/TCP,9094/UDP   22m
service/k8sgraf-grafana                           LoadBalancer   10.233.57.6     <pending>     80:30667/TCP                 22m
service/k8sgraf-kube-prometheus-st-alertmanager   ClusterIP      10.233.49.57    <none>        9093/TCP                     22m
service/k8sgraf-kube-prometheus-st-operator       ClusterIP      10.233.57.73    <none>        443/TCP                      22m
service/k8sgraf-kube-prometheus-st-prometheus     ClusterIP      10.233.52.240   <none>        9090/TCP                     22m
service/k8sgraf-kube-state-metrics                ClusterIP      10.233.23.243   <none>        8080/TCP                     22m
service/k8sgraf-prometheus-node-exporter          ClusterIP      10.233.44.146   <none>        9100/TCP                     22m
service/prometheus-operated                       ClusterIP      None            <none>        9090/TCP                     22m
```

Стандартный логин пароль — admin / prom-operator

Доступ к [дашбордам grafana](http://178.154.223.46:30667/d/z7Q5SAnVz/node-exporter-nodes?orgId=1&refresh=30s)

&nbsp;

&nbsp;

## 4.2. Деплой приложения

На [3-м шаге](https://gitlab.com/VitalyMozhaev/app) мы создали простое приложение и собрали [docker-образ](https://gitlab.com/VitalyMozhaev/app/container_registry/3434688). Пришло время запустить наше приложение на Kubernetes кластере.

Проверяем запущенные поды:
```bash
kubectl get pods
```

Если ещё не создан, создаём namespace:
```bash
kubectl create ns stage
namespace/stage created
```

Проверяем пространства имён:
```bash
kubectl get ns
NAME              STATUS   AGE
default           Active   6d19h
kube-node-lease   Active   6d19h
kube-public       Active   6d19h
kube-system       Active   6d19h
stage             Active   49s
```

Переключаемся на пространство имён stage:
```bash
kubectl config set-context --current --namespace=stage
Context "kubernetes-admin@cluster.local" modified.
```

Проверяем текущий namespace:
```bash
kubectl config view --minify | grep namespace:
        namespace: stage
```

Создаём файл `./stage/deploy.yaml`:
```text
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dp-app
  name: dp-app
  namespace: stage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dp-app
  template:
    metadata:
      labels:
        app: dp-app
    spec:
      containers:
        - image: registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0
          imagePullPolicy: IfNotPresent
          name: dp-app
      terminationGracePeriodSeconds: 30

---
apiVersion: v1
kind: Service
metadata:
  name: dp-app
  namespace: stage
spec:
  ports:
    - name: web
      port: 80
      targetPort: 80
  selector:
    app: dp-app

```

Запускаем установку deployment в Kubernetes:
```bash
kubectl apply -f ./stage/deploy.yaml
deployment.apps/dp-app created
service/dp-app created
```

Проверяем поды:
```bash
kubectl get deploy,po,svc
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/dp-app   1/1     1            1           88s

NAME                         READY   STATUS    RESTARTS   AGE
pod/dp-app-9997797bc-f4xmt   1/1     Running   0          88s

NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/dp-app   ClusterIP   10.233.51.60   <none>        80/TCP    89s
```

Настраиваем доступ к нашему приложению. Создаём файл `ingress.yaml`
```text
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dp-app
  namespace: stage
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: dp-app
            port:
              number: 80

```

Запускаем установку ingress в Kubernetes:
```bash
kubectl apply -f ./stage/ingress.yaml
ingress.networking.k8s.io/dp-app created
```

После этого можем заходить на любую из рабочих нод.
Т.к. приложение работает на порту 80, переходим по адресу: `51.250.35.102/` и видим результат работы нашего приложения.


# Заметки

#### Просмотр изменений "в реальном времени":
```bash
watch kubectl get deploy,po,svc -o wide
```

#### Удаляем все deployment:
```bash
kubectl delete deployment dp-app
```

#### Удаляем все service:
```bash
kubectl delete service dp-app
```

#### Удаление helm 
```bash
helm list
helm uninstall diplom
```

#### Доступ к приватному реестру:
```text
kubectl -n stage create secret docker-registry dockerio --docker-server=https://index.docker.io/v1/ --docker-username=mylogin --docker-password=mypass --docker-email=my@mail.ru
kubectl -n stage create secret docker-registry regcred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

Затем прописываем secret, например:
```text
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: dockerio

```
