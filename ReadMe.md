FROM nginx
COPY index.html /usr/share/nginx/html

# Remove all containers stopped
sudo docker container prune -f

# How to install and run docker with nginx on AWS
sudo yum install -y docker
sudo service docker start
sudo docker run --name zengnginx -p 80:80 -d zengemily79/nginx

sudo vi /etc/rc.d/rc.local
sudo docker container prune -f
sudo docker run --name zengnginx -p 80:80 -d zengemily79/nginx_server2
