export DEBIAN_FRONTEND=noninteractive
apt-get install -y apt-transport-https ca-certificates curl software-properties-common --assume-yes --force-yes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu jq --assume-yes --force-yes
ip addr add 192.168.3.1/30 dev eth1
ip link set eth1 up
ip route replace 192.168.0.0/16 via 192.168.3.2
docker rm $(docker ps -aq)
docker run -dit --name hostc-webserver -p 80:80 -v /var/www/:/usr/local/apache2/htdocs/ httpd:2.4
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>progetto di Andrea e Anna</title>
</head>
<body>
    <h1>The cake is a lie</h1>
</body>
</html>" > /var/www/index.html
