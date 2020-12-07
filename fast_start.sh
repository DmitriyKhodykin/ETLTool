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
sudo /opt/jupyterhub/bin/python3 -m pip install wheel jupyterhub jupyterlab ipywidgets
sudo mkdir -p /opt/jupyterhub/etc/jupyterhub/
cp jupyterhub/jupyterhub_config.py /opt/jupyterhub/etc/jupyterhub/jupyterhub_config.py
sudo mkdir -p /opt/jupyterhub/etc/systemd
cp systemd/jupyterhub.service /opt/jupyterhub/etc/systemd/jupyterhub.service
npm install -g configurable-http-proxy
sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service
sudo systemctl daemon-reload
sudo systemctl enable jupyterhub.service

# Conda
curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > conda.gpg
sudo install -o root -g root -m 644 conda.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
sudo apt update
sudo apt install -y conda
sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
sudo mkdir /opt/conda/envs/
sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/python python=3.8 ipykernel
sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (default)"

sudo systemctl start jupyterhub.service

# petl, pandas
sudo /opt/jupyterhub/bin/python3 -m pip install petl pandas

# Cronicle
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node
/opt/cronicle/bin/control.sh setup
cp systemd/cronicle.service /etc/systemd/system/cronicle.service
cp cronicle/useradd.js /opt/cronicle/bin/
systemctl daemon-reload
systemctl enable cronicle.service
systemctl start cronicle.service

sudo ufw allow 3012/tcp

# NGINX
sudo apt install -y nginx
rm /etc/nginx/sites-enabled/default
cp nginx/default.conf /etc/nginx/conf.d/default.conf
service nginx restart
sudo ufw allow 'Nginx HTTP'

# Шаблон для корневой ссылки
cp -r html /var/www

# PostgreSQL
sudo apt install -y postgresql postgresql-contrib
cp -f postgresql/postgresql.conf /etc/postgresql/12/main/
cp -f postgresql/pg_hba.conf /etc/postgresql/12/main/
sudo ufw allow postgresql/tcp
sudo ufw allow 5432/tcp
service postgresql restart

cat << EOF

Installation complete!

To add new user please run user.sh -u

Please change admin cronicle password, run user.sh -a

EOF


