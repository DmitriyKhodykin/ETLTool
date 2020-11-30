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
- Papermill - инструмент для запуска кода внутри Jupyter Notebooks вне среды Jupyter Lab (необходим для запуска Notebooks по расписанию из Cronicle)
- PETL и Pandas - для обработки табличных данных
- Requests - Python-библиотека для работы с HTTP-запросами
- Cronicle - планировщик заданий с WEB-интерфейсом
- MySQL - система управления базами данных

## Алгоритм установки и настройки OC Ubuntu

Операционная система (ОС) на базе ядра GNU Linux Ubuntu 20.04 LTS может быть развернута на облачном виртуальном сервере, например, предоставляемым провайдером REG.ru. По ссылке представлены возможные конфигурации и стоимость аренды сервера: https://www.reg.ru/vps/cloud/. В рамках подготовки настоящей инструкции использовался сервер Cloud 2a c 2-х ядерным процессором и 1 GB оперативной памяти, который позволяет разворачивать указанную ОС. После аренды сервера вы получите имя пользователя - `root` и пароль для удаленного доступа на указанный при регистрации адрес электронной почты.

Шаг 1 — Вход в систему под именем Root

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

После запуска Jupyter Hub доступен по адресу http://YOUR_SERVER_HOSTNAME:8000/

Логин и пароль - аналогичны логину и паролю для входа в Linux-систему.

Подробнее об установке Jupyter Hub и Jupyter Lab https://jupyterhub.readthedocs.io/en/stable/installation-guide-hard.html

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

Запуск сервера:

```
/opt/cronicle/bin/control.sh start
```

Проверка работоспособности (получение доступа на стороне клиента - браузера):

```
http://YOUR_SERVER_HOSTNAME:3012/
```

Подробнее об установке Cronicle: https://github.com/jhuckaby/Cronicle
