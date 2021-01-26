#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
    then echo "Please run with sudo"
    exit
fi

# Установка nodejs 14.15.*
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
echo "Установка nodejs"
sleep 2
sudo apt-get -qq install -y nodejs

# JupyterHub + JupyterLab
echo "Установка pip"
sleep 2
sudo apt-get -qq install -y python3-pip

echo "Установка papermill"
sleep 2
sudo python3 -m pip install -q papermill

echo "Установка venv"
sleep 2
sudo apt-get -qq install -y python3-venv

echo "Создание venv jupyterhub"
sleep 2
sudo python3 -m venv /opt/jupyterhub/

echo "Установка wheel"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q wheel

echo "Установка jupyterhub"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q jupyterhub

echo "Установка jupyterlab"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q jupyterlab

echo "Установка ipwidgets"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q ipywidgets
sudo mkdir -p /opt/jupyterhub/etc/jupyterhub/

echo "Копирование конфига jupyterhub_config.py"
sleep 2
cp jupyterhub/jupyterhub_config.py /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py
sudo mkdir -p /opt/jupyterhub/etc/systemd

echo "Файл сервиса jupyterhub.service"
sleep 2
cp systemd/jupyterhub.service /opt/jupyterhub/etc/systemd/jupyterhub.service

echo "Установка configurable-http-proxy"
sleep 2
npm install -g configurable-http-proxy
sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service

echo "Активация сервиса jupyterhub"
sleep 2
sudo systemctl daemon-reload
sudo systemctl enable jupyterhub.service

# Conda
sudo curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list

echo "Установка conda"
sleep 2
sudo apt-get -qq install -y conda
sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
sudo mkdir /opt/conda/envs/

echo "Создание envs"
sleep 2
sudo /opt/conda/bin/conda create -y --prefix /opt/conda/envs/python python=3.8 ipykernel
sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (default)"

echo "Запуск сервиса"
sleep 2
sudo systemctl start jupyterhub.service

# petl, pandas
echo "Установка petl"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q petl
echo "Установка pandas"
sleep 2
sudo /opt/jupyterhub/bin/python3 -m pip install -q pandas

# Cronicle
echo "Установка cronicle"
sleep 2
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node
/opt/cronicle/bin/control.sh setup
cp systemd/cronicle.service /etc/systemd/system/cronicle.service
cp cronicle/useradd.js /opt/cronicle/bin/

echo "Запуск сервиса cronicle"
sleep 2
systemctl daemon-reload
systemctl enable cronicle.service
systemctl start cronicle.service

sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/dpkg/lock-frontend
sudo dpkg --configure -a

# NGINX
echo "Установка NGINX"
sleep 2
sudo apt-get -qq install -y nginx
rm /etc/nginx/sites-enabled/default
cp nginx/default.conf /etc/nginx/conf.d/default.conf
service nginx restart

# Шаблон для корневой ссылки
echo "Заглушка корневой страницы"
sleep 2
cp -r html /var/www

sudo killall apt apt-get # по какой-то причине иногда процесс остаётся и дальше всё слитает

# PostgreSQL
echo "Установка PostgreSQL"
sleep 2
sudo apt-get -qq install -y postgresql postgresql-contrib
cp -f postgresql/postgresql.conf /etc/postgresql/12/main/
cp -f postgresql/pg_hba.conf /etc/postgresql/12/main/
service postgresql restart

# UFW
echo "Базовая настройка UFW"
sleep 2
sudo ufw allow ssh
sudo ufw allow openssh
sudo ufw allow 3012/tcp
sudo ufw allow 'Nginx HTTP'
sudo ufw allow postgresql/tcp
sudo ufw allow 5432/tcp
sudo ufw enable

# Завершение установки
echo "Изменение пароля админа Cronicle"
sleep 2
bash ./user.sh -a

echo "Создание первого пользователя"
sleep 2
bash ./user.sh -u

echo "Установка завершена!"
