# 5. Установка и настройка CI/CD

Модифицируем наше приложение для работы процессов Gitlab CI/CD.

## Подготовка:

Создадим каталог для запуска процессов Gitlab CI/CD:
```bash
mkdir -p ~/gitlab-ci-cd/{sa,app} && cd ~/gitlab-ci-cd
mkdir -p ~/gitlab-ci-cd/app/{conf,content}
```

Создадим файлы для деплоя приложения:

- [app/](https://gitlab.com/VitalyMozhaev/cicd/-/tree/main/app) - каталог с настройками сборки приложения
    - [conf/nginx.conf](https://gitlab.com/VitalyMozhaev/cicd/-/blob/main/app/conf/nginx.conf) - конфиг для Nginx (web-сервер для приложения)
    - [content/index.html](https://gitlab.com/VitalyMozhaev/cicd/-/blob/main/app/content/index.html) - статическая страничка приложения
    - [deploy.yaml](https://gitlab.com/VitalyMozhaev/cicd/-/blob/main/app/deploy.yaml) - сценаций запуска приложения в Kubernetes
    - [Dockerfile](https://gitlab.com/VitalyMozhaev/cicd/-/blob/main/app/Dockerfile) - сценаций сборки образа
- [gitlab-ci.yml](https://gitlab.com/VitalyMozhaev/cicd/-/blob/main/.gitlab-ci.yml) - сценарий процессов Gitlab CI/CD

## UPD: не рабочий вариант.

Создадим сервис аккаунт:
```bash
kubectl apply -f ~/gitlab-ci-cd/sa/gitlab-service-account.yaml
```

Из файла не получилось создать, пришлось создал руками в YC.

Сервисный аккаунт `gitlab-admin` с правами доступа `gitlab-admin`


Получим токен сервисного аккаунта:
```bash
kubectl -n kube-system get secrets -o json | \
jq -r '.items[] | select(.metadata.name | startswith("gitlab-admin")) | .data.token' | \
base64 --decode
```

## Настройка GitLab

Заходим в интерфейс GitLab.

В пункте меню `Settings` — `CI/CD` нужно нажать на кнопку `Expand` в секции `Variables` и затем на кнопку `Add variable`.

В открывшейся форме требуется указать имя переменной, которое будет впоследствии использоваться в секции deploy манифеста `gitlab-ci.yml` — `K8S_CI_TOKEN`. В качестве значения переменной нужно использовать скопированный ранее токен сервисного аккаунта. Также следует снять флажок `Protect variable`, который разрешает доступ к переменным исключительно из ветки master. И нужно установить флажок `Mask variable` — в таком случае переменная будет закрытой, то есть ее значение не будет отображаться внутри логов CI/CD.

По такому же принципу добавил следующие переменные:

- K8S_CI_TOKEN - токен сервисного аккаунта, полученный командой выше
- KUBE_SERVER - адрес Control plain node (https://1.2.3.4:6443)
- DOCKER_REGISTRY - адрес реестра Docker контейнеров (registry.gitlab.com)
- DOCKER_USER - пользователь gitlab.com
- DOCKER_PASSWORD - пароль пользователя gitlab.com
- CONTAINER_IMAGE - название контейнера (registry.gitlab.com/vitalymozhaev/app/dp_app)

Последнее, что необходимо сделать перед запуском деплоя, — добавить в Kubernetes возможность авторизации в GitLab, чтобы получать из Docker Registry формируемый образ и запускать на его основе приложение. Для этого нужно добавить Deploy token.

В GitLab необходимо выбрать пункт меню «Repository» и нажать на кнопку «Expand» в секции «Deploy tokens».

## Проблема

Не получилось настроить доступ к Kubernetes через сервисный аккаунт. Возможно недостаточно прав или что-то не прописал.

&nbsp;

&nbsp;

# Решение (Рабочий вариант):

Для настройки доступа к Kubernetes кластеру из Gitlab был использован другой подход.

Создаём пользователя Kubernetes с ограниченными правами

Файл .kube/config перенесён как переменная Gitlab в base64:
```bash
cat ~/.kube/config | base64
# Копируем длинный вывод
```

### Заходим в интерфейс GitLab.

В пункте меню `Settings` — `CI/CD` нужно нажать на кнопку `Expand` в секции `Variables` и затем на кнопку `Add variable`.

В открывшейся форме требуется указать имя переменной, которое будет впоследствии использоваться в секции deploy манифеста `gitlab-ci.yml` — `KUBE_CONFIG`. В качестве значения переменной нужно использовать скопированный ранее файл `.kube/config` в `base64`. Также следует снять флажок `Protect variable`, который разрешает доступ к переменным исключительно из ветки master. Флажок `Mask variable` — не включать, иначе будет ругаться и не сохранит переменную.

По такому же принципу добавил следующие переменные:

- DOCKER_REGISTRY - адрес реестра Docker контейнеров (registry.gitlab.com)
- DOCKER_USER - пользователь gitlab.com
- DOCKER_PASSWORD - пароль пользователя gitlab.com
- CONTAINER_IMAGE - название контейнера (registry.gitlab.com/vitalymozhaev/app/dp_app)
- KUBE_CONFIG - Файл .kube/config в base64

### Дописываем .gitlab-ci.yml

Загрузка образа в [Gitlab Container Registry](https://gitlab.com/VitalyMozhaev/app/container_registry/3434688) образа происходит с тегом `:${CI_COMMIT_SHORT_SHA}`, который Gitlab создаёт автоматически, а также тегом `:latest` для запуска последней версии.

```text
build:
  stage: build
  before_script:
    - docker login ${DOCKER_REGISTRY} -u "${DOCKER_USER}" -p "${DOCKER_PASSWORD}"
  script:
    - docker build -t ${CONTAINER_IMAGE} -t latest ./app
    - docker tag ${CONTAINER_IMAGE} ${CONTAINER_IMAGE}:${CI_COMMIT_SHORT_SHA}
    - docker push ${CONTAINER_IMAGE}:${CI_COMMIT_SHORT_SHA}
    - docker push ${CONTAINER_IMAGE}:latest
```

На этапе развертывания мы можем декодировать эту переменную обратно в файл и использовать ее с kubectl.
```text
...
variables:
  KUBECONFIG: /etc/deploy/config
...
deploy:
  stage: deploy
  needs: ["test"]
  image: dtzar/helm-kubectl
  script:
    - mkdir -p /etc/deploy
    - echo ${KUBE_CONFIG} | base64 -d > ${KUBECONFIG}
    - kubectl config use-context kubernetes-admin@cluster.local
    - sed -i "s/__teg__/${CI_COMMIT_SHORT_SHA}/g" ./app/deploy.yaml
    - kubectl apply -f ./app
  only:
    - main
```

### Особенности:
- Сборка (build) образа происходит при любом коммите
- Тестирование (test) и развёртывание в Kubernetes (deploy) только на ветке мастер, зависят от build.
- Развёртывание в Kubernetes происходит из файла deploy.yaml, в котором указан тег в виде метки `__teg__`, которая заменяется на текущиее значение сборки `${CI_COMMIT_SHORT_SHA}`

Все `Pipelines` доступны по ссылке [Pipelines](https://gitlab.com/VitalyMozhaev/cicd/-/pipelines).

Все собранные образы прилодения хранятся в [Container Registry](https://gitlab.com/VitalyMozhaev/app/container_registry/3434688)

## PS:

Конечно, эта схема не идеальная. Тут не учитывается откат к предыдущему релизу, не запускаются UnitTests и многое другое.

Однако этот варикнт позволяет наглядно продемонстрировать возможность автоматизации процессов CI/CD и реализации подхода Инфраструктура как код.

Выражаю благодарность всем преподавателям, наставникам и организаторам Netology. Большое спасибо за проделанную работу, подготовленные и проработанные материалы.
