# 3. Создание тестового приложения

## Подготовка:

Создаём каталог `app` и подкаталоги `conf` и `content`:
```
mkdir -p ~/app/{conf,content} && cd ~/app/
```

В каталоге `app` создаём `Dockerfile`:
```text
FROM nginx:latest

# Configuration
ADD conf /etc/nginx
# Content
ADD content /usr/share/nginx/html

EXPOSE 80

```

Также создаём файл `~/app/conf/nginx.conf` с конфигурацией nginx:
```text
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    server {
        listen   80;

        location / {
            gzip off;
            root /usr/share/nginx/html/;
            index index.html;
        }
    }
    keepalive_timeout  65;
}

```

И создаём статическую страницу нашего приложения:
```text
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8" name="viewport" content="width=device-width, initial-scale=1" />
    <title>This is Vitaly`s diplom for DevOps-7 Netology</title>
</head>

<body>
    <h2 style="margin-top: 150px; text-align: center;">This is Vitaly`s diplom for DevOps-7 Netology</h2>
</body>

</html>
```

### Собираем образ:

```bash
docker build -t registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0 .
```

Запускаем контейнер:
```bash
docker run -d --name app -p80:80 registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0

docker ps -a
CONTAINER ID   IMAGE                                                 COMMAND                  CREATED         STATUS         PORTS                               NAMES
9fd20a4c22b6   registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0   "/docker-entrypoint.…"   4 seconds ago   Up 4 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   app
```

Проверяем работу приложения:

![Приложение работает](app_index.png)

Приложение работает.

Останавливаем контейнер:
```bash
docker stop app
```

Проверяем список образов:
```bash
docker images
```

Подключаемся к реестру:
```bash
docker login registry.gitlab.com -u vitalymozhaev
```

---

Встретился с проблемой:

`Error saving credentials: error storing credentials - err: exit status 1, out: Cannot autolaunch D-Bus without X11 $DISPLAY`

Решение:
```bash
sudo apt install gnupg2 pass
```

---

Загружаем образ в хранилище:
```bash
docker push registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0
```

Запуск из хранилища
```bash
docker run -d --name app -p80:80 registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0
```


## Заметки

Использование переменных в Dockerfile:

```bash
echo VARIABLE1=foobar1 > my-env.txt
echo VARIABLE2=foobar2 >> my-env.txt
echo VARIABLE3=foobar3 >> my-env.txt

docker run --env-file my-env.txt alpine:3 env
```

Использование GIT в Dockerfile:

```bash
ARG username=$GIT_USERNAME
ARG password=$GIT_PASSWORD
RUN git clone https://username:password@github.com:eugenp/tutorials.git
```

Сохраняем образ:
```bash
docker commit -m "Save App images" -a "Vitaly Mozhaev" app registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0
```

Добавляем тэг:
```bash
docker tag dp_app:v1.0.0 registry.gitlab.com/vitalymozhaev/app/dp_app:v1.0.0
```
