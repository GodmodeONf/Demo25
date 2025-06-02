apt-get install -y tzdata
hostnamectl set-hostname br-srv.au-team.irpo;
timedatectl set-timezone Europe/Samara

cd /etc/net/ifaces
cd ens18
vim options
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
echo "192.168.24.30/27" > /etc/net/ifaces/ens18/ipv4address
echo "default via 192.168.24.1" > /etc/net/ifaces/ens18/ipv4route
echo nameserver 8.8.8.8 > /etc/resolv.conf
ip -c -br a
ip route show
ip a show

timedatectl set-timezone Europe/Samara
systemctl restart network

useradd sshuser -u 1010
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
cat <<EOF /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL
EOF

CONFIG_FILE="/etc/openssh/sshd_config"

echo "AllowUsers sshuser" | tee -a /etc/openssh/sshd_config
awk -i inplace '/^#?Port[[:space:]]+22$/ {sub(/^#/,""); sub(/22/,"2024"); print; next} {print}' "$CONFIG_FILE"
awk -i inplace '/^#?MaxAuthTries[[:space:]]+6$/ {sub(/^#/,""); sub(/6/,"2"); print; next} {print}' "$CONFIG_FILE"
awk -i inplace '/^#?PasswordAuthentication[[:space:]]+(yes|no)$/ {sub(/^#/,""); sub(/no/,"yes"); print; next} {print}' "$CONFIG_FILE"
awk -i inplace '/^#?PubkeyAuthentication[[:space:]]+(yes|no)$/ {sub(/^#/,""); sub(/no/,"yes"); print; next} {print}' "$CONFIG_FILE"

touch /etc/openssh/bannermotd  
cat <<EOF > /etc/openssh/bannermotd 
Authorized access only  
EOF  

systemctl restart sshd  

#Создание NTP
apt-get install chrony -y 
sed -i '3i#pool pool.ntp.org iburst' /etc/chrony.conf
systemctl enable --now chronyd

cat <<EOF >> /etc/resolv.conf 
nameserver 8.8.8.8
EOF

#Создание Samba DC
apt-get update && apt-get install -y task-samba-dc bind 
control bind-chroot disabled
grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
systemctl stop bind
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol
samba-tool domain provision 
systemctl restart samba
systemctl enable --now samba
samba-tool domain info 127.0.0.1
samba-tool computer list
samba-tool group add hq
for i in {1..5}; do
samba-tool user add user$i-hq P@ssw0rd;
samba-tool user setexpiry user$i-hq --noexpiry;
samba-tool group addmembers "hq" user$i-hq;
done
apt-get install -y admx-*
amdx-msi-setup

#Настройка Ansible
apt-get install -y ansible sshpass
sed -i 's/^#inventory      = \/etc\/ansible\/hosts/inventory      = \/etc\/ansible\/hosts/' /etc/ansible/ansible.cfg 
echo "host_key_checking  False" | tee -a /etc/ansible/ansible.cfg
cat > /etc/ansible/hosts <<EOF
HQ-RTR ansible_host=192.168.23.1 ansible_user=net_admin ansible_password=P@$$word ansible_connection=network_cli ansible_network_os=ios
BR-RTR ansible_host=192.168.22.1 ansible_user=net_admin ansible_password=P@$$word ansible_connection=network_cli ansible_network_os=ios
HQ-SRV ansible_host=192.168.23.62 ansible_user=sshuser ansible_password=P@ssw0rd ansible_ssh_port=2024
HQ-CLI ansilbe_host=192.168.23.66 ansible_user=sshuser ansible_password=P@ssw0rd ansible_ssh_port=2024

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
ansible -m ping all

#Установка Docker 
systemctl disable —now ahttpd
apt-get install -y docker-{ce,compose}
systemctl enable --now docker

touch /home/sshuser/wiki.yaml
cat <<EOF > /home/sshuser/wiki.yaml
services:
  mediawiki:
    container_name: wiki
    image: mediawiki
    restart: always
    ports:
      - "8080:80"
    links:
      - db
#    volumes:
#      - ./LocalSettings.php:/var/www/html/LocalSettings.php

  db:
    container_name: mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_DATABASE: mediawiki
      MARIADB_USER: wiki
      MARIADB_PASSWORD: WikiP@ssw0rd
      MARIADB_ROOT_PASSWORD: P@ssw0rd
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

grep -E "Port|MaxAuthTries|PasswordAuthentication|PubkeyAuthentication" "$CONFIG_FILE"

