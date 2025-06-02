apt-get install -y tzdata
hostnamectl set-hostname isp; exec bash
timedatectl set-timezone Europe/Samara

cd /etc/net/ifaces/
cp -r ens18/ ens19
cd ens19
vim options
BOOTPROTO=static
TIPE=eth
DISABLED=no
ONBOOT=yes
cd ens19
echo "172.16.4.1/28 >> ipv4address
cd..
cp -r ens19/ ens20
echo "172.16.5.1/28" > ens20/ipv4address
systemctl restart network
ip -c br a
vim /etc/net/sysctl.conf
net.ipv4.ip_forward = 1
sysctl -w net.ipv4.ip_forward=1
apt-get update && apt-get install -y iptables
ipbables -A POSTROUTING -t nat -s 172.16.4.0/28 -o ens18 -j MASQUERADE
ipbables -A POSTROUTING -t nat -s 172.16.5.0/28 -o ens18 -j MASQUERADE
iptables -t nat -L
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables.service

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

touch /etc/openssh/banner  
cat <<EOF > /etc/openssh/banner 
Authorized access only  
EOF  

systemctl restart sshd  


hostnamectl set-hostname ISP; exec bash

