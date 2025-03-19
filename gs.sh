#!/bin/bash

read -p "iniciar a instalação do servidor web e configurar o dns? (s/n): " confirm
if [[ "$confirm" != "s" ]]; then
    echo "instalação cancelada."
    exit 1
fi

echo "realizando backup"
cp /etc/network/interfaces /etc/network/interfaces.bak
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
cp -r /etc/apache2 /etc/apache2.bak
echo "backup concluído."
echo "atualizando pacotes"
apt update -y

echo "instalando apache"
apt install apache2 -y

systemctl start apache2
systemctl enable apache2

echo "baixando template"
wget -q -O /var/www/html/index.html (url)

echo "ajustando permissões"
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "instalando bind"
apt install bind9 -y

echo "configurando"

bash -c 'cat > /etc/bind/db.meudominio <<EOF
;
; BIND data file for local loopback interface
;
$TTL    604800
@       IN      SOA     ns1.meudominio.com. root.meudominio.com. (
                      2         ; Serial
                 604800         ; Refresh
                  86400         ; Retry
                2419200         ; Expire
                 604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.meudominio.com.
@       IN      A       192.168.1.100
ns1     IN      A       192.168.1.100
www     IN      A       192.168.1.100
EOF'


bash -c 'echo "zone \"meudominio.com\" {
    type master;
    file \"/etc/bind/db.meudominio\"; 
};" >> /etc/bind/named.conf.local'


echo "reiniciando o bind para aplicar as configurações"
systemctl restart bind9

echo "configurando ip"
bash -c 'cat > /etc/network/interfaces <<EOF
auto enp0s8
iface enp0s8 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.100
EOF'

echo "aplicando nova configuração de rede"
systemctl restart networking
ifdown enp0s3 --force && sudo ifup enp0s3

echo "realizando backup automático dos diretórios"

backup_dir="/backups/$(date +%F)"
mkdir -p "$backup_dir"
cp -r /var/www/html "$backup_dir"
cp -r /etc/bind "$backup_dir"
echo "backup automático concluído. (arquivos salvos em $backup_dir)"


echo "configuração concluída :)"
echo "acesse http://192.168.1.100 ou http://www.meudominio.com para verificar o template."
