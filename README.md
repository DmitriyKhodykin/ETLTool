# Инструкция по сборке инструмента для ETL на основе сервера с Ubuntu 20.04

## Аннотация

Настоящая инструкция позволяет сконфигурировать инструмент для ETL (Extract -> Transform -> Load) для автоматизированного сбора, обработки и сохранения данных в базу данных PostgreSQL.

Особенностью инструмента является:
- WEB-интерфейс (доступ с любого ПК через браузер)
- Возможность создания ETL-скриптов на таких языках программирования как Python, R, Scala
- Разграничение прав доступа между различными пользователями
- Наличие инструмента для запуска скриптов ETL по расписанию в любое необходимое время с необходимой периодичностью

## Используемые решения

Для сборки ETL-инструмента используются следующие компоненты:
- ОС - Ubuntu 20.04 на виртуальном сервере
- Jupyter Lab - инструмент с WEB-интерфейсом для создания и запуска скриптов в режиме ноутбука
- Jupyter Hub - многопользовательский сервер для запуска Jupyter Notebooks (в которых аналитики будут непосредственно создавать ETL-скрипты)
- Conda - менеджер виртуальных окружений для запуска Python-кода
- Papermill - инструмент для запуска кода внутри Jupyter Notebooks вне среды Jupyter Lab (необходим для запуска Notebooks по расписанию из Cronicle)
- PETL и Pandas - для обработки табличных данных
- Requests - Python-библиотека для работы с HTTP-запросами
- Cronicle - планировщик заданий с WEB-интерфейсом
- PostgreSQL - система управления базами данных

## Алгоритм установки и настройки OC Ubuntu

Операционная система (ОС) на базе ядра GNU Linux Ubuntu 20.04 LTS может быть развернута на облачном виртуальном сервере, например, предоставляемым провайдером REG.ru. По ссылке представлены возможные конфигурации и стоимость аренды сервера: https://www.reg.ru/vps/cloud/. В рамках подготовки настоящей инструкции использовался сервер Cloud 2a c 2-х ядерным процессором и 1 GB оперативной памяти, который позволяет разворачивать указанную ОС. После аренды сервера вы получите имя пользователя - `root` и пароль для удаленного доступа на указанный при регистрации адрес электронной почты.

Шаг 1 — Вход в систему под именем root

```
ssh root@your_server_ip
```

Шаг 2 — Создание нового пользователя (например, с именем sammy)

```
adduser sammy
```

Шаг 3 — Предоставление прав администратора

```
usermod -aG sudo sammy
```

Шаг 4 — Установка простого брандмауэра (UFW)

```
# ufw app list

Output
Available applications:
OpenSSH

# ufw allow OpenSSH
# ufw enable
# ufw status

Output
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
```

Шаг 5 — Предоставление внешнего доступа для обычного пользователя

```
ssh sammy@your_server_ip
```

Подробнее о начальной настройке сервера: https://www.digitalocean.com/community/tutorials/ubuntu-18-04-ru

## Установка Node.js

Для последующих инстансов потребуется Node.js - среда для запуска Java Script.

Будем устанавливать крайнюю актуальную версию LTS. Уточнить эту версию можно по ссылке: https://nodejs.org/en/about/releases/

Крайней считается версия перед `Current`

Добавление репозитория:

```
cd ~
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
```

Установка:

```
sudo apt install nodejs
```

Пакет NodeSource nodejs содержит двоичный код node и npm, так что не нужно устанавливать `npm` отдельно.

Проверка установленной версии:

```
node -v
npm -v

Output
v14.2.0
```

Подробнее об установке Node.js: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-20-04-ru

## Установка Jupyter Hub и Jupyter Lab

Для начала установим PIP:

```
sudo apt update
sudo apt install python3-pip
```

Установим пакет для работы с виртуальными средами:

```
sudo apt install python3-venv
```

Создадим виртуальную (изолированную) среду разработки:

```
sudo python3 -m venv /opt/jupyterhub/
```

Далее, будем устанавливать пакеты в созданное виртуальное окружение.

Python wheels для быстрой установки зависимостей:

```
sudo /opt/jupyterhub/bin/python3 -m pip install wheel
```

Jupyter Hub и Jupyter Lab:

```
sudo /opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab
```

HTML-виджеты:

```
sudo /opt/jupyterhub/bin/python3 -m pip install ipywidgets
```

### Конфигурационные файлы для Jupyter Hub

```
sudo mkdir -p /opt/jupyterhub/etc/jupyterhub/
cd /opt/jupyterhub/etc/jupyterhub/
sudo /opt/jupyterhub/bin/jupyterhub --generate-config
```

Крайняя инструкция создаст конфигурационный файл /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py

```
sudo nano /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py
```

Внутри конфигурационного файла:

```
c.Spawner.default_url = '/lab'
c.JupyterHub.bind_url = 'http://localhost:8000/lab'
```

### Настройка Jupyter Hub как сервиса

```
sudo mkdir -p /opt/jupyterhub/etc/systemd
sudo nano /opt/jupyterhub/etc/systemd/jupyterhub.service
```

Внутри файла конфигурации:

```
[Unit]
Description=JupyterHub
After=syslog.target network.target

[Service]
User=root
Environment="PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/jupyterhub/bin"
ExecStart=/opt/jupyterhub/bin/jupyterhub -f /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py

[Install]
WantedBy=multi-user.target
```

Конфигурируемый http-proxy:

```
npm install -g configurable-http-proxy
```

Запустим сервис:

```
sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service
sudo systemctl daemon-reload
sudo systemctl enable jupyterhub.service
sudo systemctl start jupyterhub.service
sudo systemctl status jupyterhub.service
```

### Установка и настройка Conda

Мы будем использовать conda для управления виртуальными средами Python.

```
curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
sudo apt update
sudo apt install conda
```

Наконец, мы можем сделать conda более доступной для пользователей, установив символическую ссылку на сценарий установки оболочки conda в папку «drop in» профиля, чтобы он запускался при входе в систему.

```
sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
```

Установим conda по-умолчанию для пользователей:

```
sudo mkdir /opt/conda/envs/
sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/python python=3.8 ipykernel
sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (default)"
sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix /usr/local/ --name 'python' --display-name "Python (default)"
```

Настройка собственных пользовательских сред conda:

Администратору здесь относительно мало что нужно сделать, поскольку пользователям придется настраивать свои собственные среды с помощью оболочки. При входе в систему они должны запустить `conda init` или `/opt/conda/bin/conda`. Затем они могут использовать conda для настройки своей среды, хотя они также должны установить ipykernel. После этого они могут включить свое ядро, используя:

```
/path/to/kernel/env/bin/python -m ipykernel install --name 'python-my-env' --display-name "Python My Env"
```

Подробнее об установке Jupyter Hub + Jupyter Lab + Conda https://jupyterhub.readthedocs.io/en/stable/installation-guide-hard.html

## Настройка обратного прокси для входа в Jupyter Hub

На данный момент текущее руководство приводит к тому, что JupyterHub работает на порту 8000. Обычно не рекомендуется запускать открытые веб-службы таким способом - вместо этого используйте обратный прокси, работающий на стандартных портах HTTP / HTTPS.

Важно: помните о последствиях для безопасности, особенно если вы используете сервер, доступный из открытого Интернета, то есть не защищенный в рамках внутренней интрасети учреждения или частной домашней / офисной сети. Вам следует настроить брандмауэр. Брандмауэр будет настроен с использованием ufw.

### Использование Nginx

Здесь мы опишем шаги, необходимые для настройки Jupyter Hub с Nginx и размещения его по заданному URL-адресу, например. <your-server-ip-or-url> / jupyter
	
```
sudo apt install nginx
sudo nano /etc/nginx/sites-available/default
```

Внутри конфигурационного файла добавим блок:

```
  location /lab/ {
    # NOTE important to also set base url of jupyterhub to /lab in its config
    proxy_pass http://127.0.0.1:8000;

    proxy_redirect   off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # websocket headers
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

  }
```

Также добавим этот фрагмент перед блоком `server`

```
map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }
```

Проверка конфигурации:

```
sudo nginx -t
sudo systemctl restart nginx.service
```

## Установка Papermill, PETL, Pandas, Requests

Установка через PIP:

```
sudo /opt/jupyterhub/bin/python3 -m pip install papermill
sudo /opt/jupyterhub/bin/python3 -m pip install petl
sudo /opt/jupyterhub/bin/python3 -m pip install pandas
```

Requests входит в базовую поставку Jupyter Lab.

Документация:
- papermill: https://papermill.readthedocs.io/en/latest/
- PETL: https://petl.readthedocs.io/en/stable/
- Pandas: https://pandas.pydata.org/
- Requests: https://requests.readthedocs.io/en/master/

## Установка Cronicle

Установка осуществляется от имени root (с правами sudo от имени обычного пользователя дистрибутив не установится).

После установки Node.js:

```
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node
```

Это установит последний стабильный выпуск Chronicle и все его зависимости в: /opt/chronicle/

Если вы пожелаете установить его вручную (или что-то пошло не так с автоматической установкой), вот исходные команды:

```
mkdir -p /opt/cronicle
cd /opt/cronicle
curl -L https://github.com/jhuckaby/Cronicle/archive/v1.0.0.tar.gz | tar zxvf - --strip-components 1
npm install
node bin/build.js dist
```

Создание пользователя:

```
/opt/cronicle/bin/control.sh setup
```

Запуск сервера (желательно воспользоваться следующим шагом):

```
/opt/cronicle/bin/control.sh start
```

Для автоматической загрузки вместе с системой:

```
sudo nano /etc/systemd/system/cronicle.service
```

Внутри файла конфигурации:

```
[Unit]
Description=Cronicle
After=syslog.target network.target

[Service]
Type=forking
User=root
PIDFile=/opt/cronicle/logs/cronicled.pid
ExecStart=/opt/cronicle/bin/control.sh start
ExecStop=/opt/cronicle/bin/control.sh stop

[Install]
WantedBy=multi-user.target
```

Запустим сервис:

```
systemctl daemon-reload
systemctl enable cronicle.service
systemctl start cronicle.service
```

Проверка работоспособности (получение доступа на стороне клиента - браузера):

```
http://YOUR_SERVER_HOSTNAME:3012/
```

Подробнее об установке Cronicle: https://github.com/jhuckaby/Cronicle

## Установка nginx

Устанавливаем:

```
sudo apt install -y nginx
```

Удаляем конфиг сайтов:

```
rm /etc/nginx/sites-enabled/default
```

Создаём конфиг по умолчанию:

```
sudo nano /etc/nginx/conf.d/default.conf
```

В сам конфиг:

```
# top-level http config for websocket headers
# If Upgrade is defined, Connection = upgrade
# If Upgrade is empty, Connection = close
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

server {
	listen 80;
	index index.php index.html;
	server_name petl.efko.ru
	error_log  /var/log/nginx/error.log;
	access_log /var/log/nginx/access.log;
	root /var/www/html;

	location /lab {
		proxy_pass http://127.0.0.1:8000;
		proxy_redirect   off;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header Host $host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
		# websocket headers
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
	}
	
	location ~ /.well-known {
		allow all;
	}

}
```

Перезагрузка сервиса:

```
service nginx restart
```

Создаём HTML шаблон главной страницы:

```
sudo nano /var/www/html/index.html
```

Пишем содержимое которое вам необходимо.
