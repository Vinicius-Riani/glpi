#!/bin/bash
# Atualiza Lista de Pacotes
apt update -y
apt upgrade -y


# Removendo pacotes NTP
apt purge ntp
# Instalar pacotes OpenNTPD
apt install -y openntpd
# Parando Serviço OpenNTPD
service openntpd stop
# Configurar Timezone padrão do Servidor
dpkg-reconfigure tzdata
# Adicionar servidor NTP.BR
echo "servers pool.ntp.br" > /etc/openntpd/ntpd.conf
# Habilitar e Iniciar Serviço OpenNTPD
systemctl enable openntpd
systemctl start openntpd


#PACOTES MANIPULAÇÃO DE ARQUIVOS
apt install -y xz-utils bzip2 unzip curl git

clear
echo "#------------------------------------------#"
echo           "INSTALANDO APACHE" 
echo "#------------------------------------------#"
#
apt -y install apache2 
a2enmod rewrite
#

apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
apt -y update 
apt -y install php8.2
apt-cache policy php8.2
ls /etc/apache2/mods-available/ | grep php8.2
a2enmod php8.2
#
clear
echo "#------------------------------------------#"
echo           "INSTALANDO DEPENDENCIAS" 
echo "#------------------------------------------#"
#
apt -y install php8.2 libapache2-mod-php8.2 php8.2-soap php8.2-apcu php8.2-cli php8.2-common php8.2-curl php8.2-gd php8.2-imap php8.2-ldap php8.2-mysql php8.2-snmp php8.2-xmlrpc php8.2-xml php8.2-intl php8.2-zip php8.2-bz2 php8.2-mbstring php8.2-bcmath 
apt -y install php8.2-fpm
apt -y install bzip2 curl mycli wget ntp libarchive-tools
service apache2 restart
service php8.2-fpm restart

# Criar arquivo com conteúdo
cat > /etc/apache2/conf-available/glpi.conf << EOF
<Directory "/var/www/html/glpi">
AllowOverride All
</Directory>

EOF
# Habilitar o módulo rewrite do apache
a2enmod rewrite
# Habilita a configuração criada
a2enconf glpi.conf
# Reinicia o servidor web considerando a nova configuração
systemctl restart apache2

# Criar diretório onde o GLPi será instalado
mkdir /var/www/glpi
# Baixar o sistema GLPi
wget https://github.com/glpi-project/glpi/releases/download/10.0.17/glpi-10.0.17.tgz 
tar -xvzf glpi-10.0.17.tgz /var/www/html/glpi/
# Movendo diretórios "files" e "config" para fora do GLPi 
mv /var/www/html/glpi/files /var/www/html/glpi/
mv /var/www/html/glpi/config /var/www/html/glpi/
# Ajustando código do GLPi para o novo local dos diretórios
sed -i 's/\/config/\/..\/config/g' /var/www/html/glpi/inc/based_config.php
sed -i 's/\/files/\/..\/files/g' /var/www/html/glpi/inc/based_config.php

# Ajustar propriedade de arquivos da aplicação GLPi
chown root:root /var/www/html/glpi -Rf
# Ajustar propriedade de arquivos files, config e marketplace
chown www-data:www-data /var/www/html/glpi/files -Rf
chown www-data:www-data /var/www/html/glpi/config -Rf
chown www-data:www-data /var/www/html/glpi/marketplace -Rf
# Ajustar permissões gerais
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

# Criando link simbólico para o sistema GLPi dentro do diretório defalt do apache
#ln -s /var/www/html/glpi /var/www/html/glpi

# Instalando o Serviço MySQL
apt install -y mariadb-server

# Criando base de dados
mysql -e "create database glpi character set utf8"
# Criando usuário
mysql -e "create user 'glpi'@'localhost' identified by 'Qazplm27'"
# Dando privilégios ao usuário
mysql -e "grant all privileges on glpi.* to 'glpi'@'localhost' with grant option";


# Habilitando suporte ao timezone no MySQL/Mariadb
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
# Permitindo acesso do usuário ao TimeZone
mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost';"
# Forçando aplicação dos privilégios
mysql -e "FLUSH PRIVILEGES;"
