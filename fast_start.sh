#!/usr/bin/env bash

# Установка nodejs 14.15.1
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install -y nodejs

# JupyterHub + JupyterLab
sudo apt install -y python3-pip
sudo python3 -m pip install papermill
sudo apt install -y python3-venv
sudo python3 -m venv /opt/jupyterhub/
sudo /opt/jupyterhub/bin/python3 -m pip install wheel
sudo /opt/jupyterhub/bin/python3 -m pip install jupyterhub jupyterlab
sudo /opt/jupyterhub/bin/python3 -m pip install ipywidgets
sudo mkdir -p /opt/jupyterhub/etc/jupyterhub/
cp jupyterhub/jupyterhub_config.py /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py
sudo mkdir -p /opt/jupyterhub/etc/systemd
cp systemd/jupyterhub.service /opt/jupyterhub/etc/systemd/jupyterhub.service
npm install -g configurable-http-proxy
sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service
sudo systemctl daemon-reload
sudo systemctl enable jupyterhub.service

# Установка conda
curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
sudo apt update
sudo apt install -y conda
sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
sudo mkdir /opt/conda/envs/
sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/python python=3.8 ipykernel
sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix /usr/local/ --name 'python' --display-name "Python (default)"

# Запуск Jupyter
sudo systemctl start jupyterhub.service

# PETL, Pandas
sudo /opt/jupyterhub/bin/python3 -m pip install petl
sudo /opt/jupyterhub/bin/python3 -m pip install pandas

# Cronicle
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node
/opt/cronicle/bin/control.sh setup
cp systemd/cronicle.service /etc/systemd/system/cronicle.service
systemctl daemon-reload
systemctl enable cronicle.service
systemctl start cronicle.service

# NGINX
sudo apt install -y nginx
rm /etc/nginx/sites-enabled/default
cp nginx/default.conf /etc/nginx/conf.d/default.conf
service nginx restart

# Шаблон для корневой ссылки
cp -r html /var/www



