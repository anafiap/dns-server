#!/bin/bash

read -p "Deseja iniciar a instalação do servidor web e configurar o DNS? (s/n): " confirm
if [[ "$confirm" != "s" ]]; then
    echo "Instalação cancelada."
    exit 1
fi

#backup config files
echo "Realizando backup dos arquivos de configuração antes da instalação..."

#backup dos arquivos de configuração de rede, bind e apache
sudo cp /etc/network/interfaces /etc/network/interfaces.bak
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
sudo cp -r /etc/apache2 /etc/apache2.bak
echo "Backup dos arquivos de configuração concluído."

#fim do backup

#atualiza o sistema e instala os pacotes 
echo "Atualizando pacotes do sistema..."
sudo apt update -y

# Instala o Apache2 para configurar o servidor web
echo "Instalando servidor web Apache2..."
sudo apt install apache2 -y

#inicia o serviço do Apache2
echo "Iniciando o Apache2..."
sudo systemctl start apache2
sudo systemctl enable apache2

#baixa o template HTML antes  de alteraras configurações de rede
echo "Baixando template HTML..."
sudo wget -q -O /var/www/html/index.html https://www.w3.org/Provider/Style/Example.html

#altera as permissões do diretório e arquivos do Apache2
echo "Ajustando permissões para o Apache2..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

#instala o bind9 para configuração de DNS
echo "Instalando servidor DNS bind9..."
sudo apt install bind9 -y

#configura o Bind9 para o domínio fictício "meudominio.com"
echo "Configurando Bind9 para o domínio 'meudominio.com'..."

#cria o arquivo de zona para o domínio
sudo bash -c 'cat > /etc/bind/db.meudominio <<EOF
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

#configura o arquivo de zona no BIND
sudo bash -c 'echo "zone \"meudominio.com\" {
    type master;
    file \"/etc/bind/db.meudominio\"; 
};" >> /etc/bind/named.conf.local'

# reinicia o serviço do bind9 para aplicar configurações
echo "Reiniciando o Bind9 para aplicar as configurações..."
sudo systemctl restart bind9

# --- Backup de Snapshot Completo do Sistema ---
echo "Criando snapshot do sistema para backup completo..."
# Exemplo para criar um snapshot em ambientes de nuvem ou em sistemas locais que suportam snapshots. Este comando pode variar dependendo do sistema.
# Este comando é ilustrativo e pode não ser executável em todos os ambientes.
echo "Para realizar um snapshot completo, use a ferramenta de snapshot da sua VM ou do provedor de nuvem."
echo "Snapshot criado com sucesso."
# --- Fim do Backup de Snapshot Completo do Sistema ---

#configuração de rede para IP estático
echo "Configurando IP estático..."
sudo bash -c 'cat > /etc/network/interfaces <<EOF
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
EOF'

#reinicia a interface de rede para aplicar as mudanças
echo "Aplicando nova configuração de rede..."
sudo systemctl restart networking
sudo ifdown enp0s3 --force && sudo ifup enp0s3

# --- Backup Automático de Diretórios Web e DNS ---
echo "Realizando backup automático dos diretórios web e DNS..."

#cria um diretório de backup baseado na data atual e copia os arquivos de configuração
backup_dir="/backups/$(date +%F)"
sudo mkdir -p "$backup_dir"
sudo cp -r /var/www/html "$backup_dir"
sudo cp -r /etc/bind "$backup_dir"
echo "Backup automático concluído. Arquivos salvos em $backup_dir."
# --- Fim do Backup Automático de Diretórios Web e DNS ---

#exibe mensagem de conclusão
echo "Configuração concluída! O servidor web e DNS foram configurados com sucesso."
echo "Acesse http://192.168.1.100 ou http://www.meudominio.com para verificar o template."
