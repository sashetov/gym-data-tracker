#!/bin/bash
sudo yum update -y
sudo yum -y install git httpd mod_proxy mod_proxy_http httpd-tools nohup
systemctl start httpd
systemctl enable httpd
echo "<VirtualHost *:80>
      ServerName localhost
      ProxyPass / http://127.0.0.1:5000/
      ProxyPassReverse / http://127.0.0.1:5000/
      <Location />
        AuthType Basic
        AuthName \"Authentication Required\"
        AuthUserFile /etc/httpd/.htpasswd
        Require valid-user
      </Location>
  </VirtualHost>" > /etc/httpd/conf.d/reverse-proxy.conf
sudo htpasswd -cb /etc/httpd/.htpasswd ${htpasswd_user} ${htpasswd_password}
systemctl restart httpd
git clone https://github.com/sashetov/test.git ~/app
cd ~/app
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
nohup flask run --host=0.0.0.0 > /var/log/flask.log 2>&1 &
