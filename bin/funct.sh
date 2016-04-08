#-----------------------------------------------Fonctions-----------------------------------------------------------------------

#___________________________________________Initialisation Systeme________________________________________________________________

CreationUser(){ # fonction pour la création d'un utilisateur sans UID

touch $chemin/logInstall #Creation du fichier qui servira comme fichier log.
DATE=$(date) #récupérer la date de jour 
echo "--------------------------------------------------------------------------------------------------------" >>  $chemin/logInstall
echo "$DATE" >> $chemin/logInstall #mettre la date du jour dans le fcihier log,cela permet de connaitre le jour d'execution du script.

for l in $(cat /etc/passwd) # récupérer ligne par ligne du fichier /etc/passwd
do
Luser=$(echo $l|cut -d ':' -f1 ) #on affiche juste le nom de l'utilisateur de la ligne récupéré et on le dans une variable 
done
			if [ "$1" == "$Luser" ] # on compare le nom de l'utilisateur récupéré par le nom de l'utilisateur qu'on veut ajouter au systéme
				then # si l'utilisateur existe déja on fait rien
					echo "utilisateur $1 existe deja dans votre systeme"
				else # si l'utilisateur n'existe pas on l'ajoute.
					useradd $1 -p $(mkpasswd $1) >> $chemin/logInstall
			fi
		
}
#____________________________________________________________________________________________________________________________________________

CreationUser2(){ # focntion pour la création d'un utilisateur avec UID
 for l in $(cat /etc/passwd) #récupérer ligne par ligne du fichier /etc/passwd
do
Luser=$(echo $l|cut -d ':' -f1 ) #on affiche juste le nom de l'utilisateur de la ligne récupéré et on le dans une variable
done
for u in $(cat /etc/passwd) #récupérer ligne par ligne du fichier /etc/passwd
do
Luid=$(echo $u|cut -d ':' -f3 ) #on affiche juste l'UID e l'utilisateur de la ligne récupéré et on le dans une variable
done
			if [ "$1" == "$Luser" ] # on compare le nom de l'utilisateur récupéré par le nom de l'utilisateur qu'on veut ajouter au systéme
				then # si l'utilisateur existe déja on fait rien
					echo "utilisateur $1 existe deja dans votre systeme"
				else # si l'utilisateur n'existe pas on l'ajoute.
				if [ "$2" == "$Luid" ] # on vérifie si l'UID qu'on veut ajouter n'existe pas déja dans le systéme
				then echo "UID déja attribue vous aurez un autre UID"
					useradd $1 -p $(mkpasswd $1) >> $chemin/logInstall # on ajoute l'utilisateur sans définir l'UID
					else 
					useradd $1 -p $(mkpasswd $1) --uid $2 >> $chemin/logInstall # on ajoute l'utilisateur avec l'UID qu'on veut
					fi
			fi
		
}
#____________________________________________________________________________________________________________________________________________

VERIMYSQL(){ # fonction pour installer mysql-server et vérifier tout d'abord son existence dans le systéme

export DEBIAN_FRONTEND="noninteractive"
#---------------------INFO MYSQL qu'on veut mettre dans debconf-set-selections comme réponse aux questions------------------------------------
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWD"
#---------------------------------------------------------------------------------------------

dpkg -L $1 >> $chemin/logInstall # vérification de l'existence de package 
VALEURRECU=$(echo $?) # récupérer la valeur du résultat
if [ "$VALEURRECU" = "0" ] # la valeur 0 veut dire que le package existe,la valeur 1 veut dire que le package n'existe pas.
then
echo "-------------------> PACKAGE $1 deja installe"
MYSQL_USER_CONF=$(grep -E "^user" /etc/mysql/my.cnf|awk '{print $3}') #récupération du nom d'utilisateur par défaut de mysql
/etc/init.d/mysql stop >> /dev/null
mysqld --skip-grant-tables --skip-networking >> $chemin/logInstall & 
echo "UPDATE user SET password=PASSWORD('$MYSQL_PASSWD') WHERE user='root'; " | mysql -u $MYSQL_USER_CONF --password=$MYSQL_USER_CONF >> $chemin/logInstall # changement du mot de passe de root en cas de l'existence déja de mysql dans le systéme
echo "------------------->MOT DE PASSE MYSQL CHANGE"
else
apt-get install -y $1 >> $chemin/logInstall #installation de mysql-server-5.5
echo "-------------------> installation $1 OK"
fi
}
#____________________________________________________________________________________________________________________________________________

INSTALL2(){  # foction de l'installation de package sans verification

apt-get install -y $1 >> $chemin/logInstall
echo "-------------------> installation $1 OK"
}
INSTALL(){         #fonction de l'installaton de package phpmyadmin
export DEBIAN_FRONTEND="noninteractive"
#----------------------INFO PHPMYADMIN qu'on veut mettre dans debconf-set-selections comme réponse aux questions ------------------------
debconf-set-selections <<<  "phpmyadmin phpmyadmin/reconfigure-webserver multiselect $PMA_WEBSERVER" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/dbconfig-install boolean true" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-user string $PMA_MYSQL_ADMIN_USER" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWD" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/app-pass password $PMA_APP_USER" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/method select $PMA_MYSQL_METHOD" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/app-password-confirm password $PMA_APP_USER" 
debconf-set-selections <<<  "phpmyadmin phpmyadmin/db/app-user  string  $PMA_APP_USER"
#---------------------------------------------------------------------------------------------
PACKAGE_Recu=$(dpkg --list | grep -o $1|tail -1) #verification de l'existence de package
if [ "$PACKAGE_Recu" = "$1" ]
then 
echo "Pachkage $1 deja installe----Reconfiguration"
dpkg-reconfigure $1 >> $chemin/logInstall # si le package existe on fait une reconfiguration avec les paramétres qu'on veut
echo "-------------------> Reconfiguration $1 OK"
else
apt-get install -y $1 >> $chemin/logInstall # si le package n'existe pas on l'installe
echo "-------------------> installation $1 OK"
fi
}
#____________________________________________________________________________________________________________________________________________

Initialisation(){       #fonction pour création des utilisateur et changement du nom de la machine

CreationUser $USER1
HOSTNAMER=$(cat /etc/hostname)
if [ "$HOST" == "$HOSTNAMER" ]      #verification de l'existence du nom de machine déja
then echo "Nom de la machine $HOST exite deja"
else
echo "$HOST" > /etc/hostname # mettre le nom de la machine qu'on veut dans /etc/hostname
fi
usermod root -p $(mkpasswd $PASSROOT) #changement du mot de passe de l'utilisateur root
/etc/init.d/hostname.sh #recharger le nom de la machine
}
#___________________________________________Installation des services_________________________________________________________________

Installation(){

apt-get update >> $chemin/logInstall #mettre a jour le systéme
echo "-------------------> UPDATING SYSTEM OK"
INSTALL2 $PACKAGE1    #installation de curl
INSTALL2 $PACKAGE2    #installation de debconf
INSTALL2 $PACKAGE3    #installation d'apache2
VERIMYSQL $PACKAGE4   #installation de mysql-server-5.5
INSTALL $PACKAGE5     #installation de phpmyadmin
INSTALL2 $PACKAGE6    #installation de sudo
touch /etc/sudoers.d/sudo # creation d'un fichier dans le dossier etc/sudoers.d/
echo "$USER1  ALL = (root) NOPASSWD:ALL" >> /etc/sudoers.d/sudo #mettre cette ligne dans le fichier creer ci dessus qui permet de rendre un utilisateur comme superutilisateur sans taper mot de passe
if [ "$(echo "show databases;" | mysql -u root --password=$MYSQL_PASSWD |grep -o $MYSQL_USER)" = "$MYSQL_USER" ]   #verification de l'existence de la base de donnée
then
echo "-------------------> DATABASE $MYSQL_USER deja cree"
BASE="CREE"
else
echo "CREATE DATABASE $MYSQL_USER;" | mysql -u root --password=$MYSQL_PASSWD # Creation de la base de donnée
echo "-------------------> DATABASE $MYSQL_USER Cree"
BASE="CREE"
fi
}
#___________________________________________Recuperation des donnees__________________________________________________________________

Recuperation_Donnee() {
HOSTNAME=$(hostname) #mettre le nom de la machine dans une variable
HTTP_USER_CONF=$(grep -E "APACHE_RUN_USER" /etc/apache2/envvars|cut -d '=' -f2) #recupération du nom de l'utilisateur par defaut d'apache
MYSQL_USER_CONF=$(grep -E "^user" /etc/mysql/my.cnf|awk '{print $3}') #récupération du nom de l'utilisateur par defaut de mysql
PID_HTTP=$(pidof apache2|cut -d " " -f2) # récupérer pid de service apache2
HTTP_USER_PID=$(id $HTTP_USER_CONF |cut -d "=" -f2|cut -d "(" -f1) #récupérer uid de l'utilisateur par déaut d'apache2
PID_MYSQL=$(pidof mysqld) ## récupérer pid de service mysql
MYSQL_USER_PID=$(id $MYSQL_USER_CONF |cut -d "=" -f2|cut -d "(" -f1)  #récupérer uid de l'utilisateur par déaut de mysql
}
#___________________________________________Affichage de la verification des donnees__________________________________________________________________

Verification_Donnee_Or_changeUser () {
echo hostname = $HOSTNAME
echo http_state = $HTTP_STATE
echo mysql_state = $MYSQL_STATE
echo phpmyadmin_state = $PHPMYADMIN_STATE
echo http_user_conf = $HTTP_USER_CONF
echo mysql_user_conf = $MYSQL_USER_CONF
echo http_user_pid = $HTTP_USER_PID
echo mysql_user_pid = $MYSQL_USER_PID
echo Test_Base_Donne = $BASE
}
#_________________________________________________Test installation APACHE______________________________________________________________

Test_Installation_Apache () {
IPSERV=$(ifconfig eth0 | grep 'inet adr'|cut -d ":" -f2|cut -d" " -f1) # Récupération de l'adresse ip de la machine
DOSSIERWEB1=$(cat /etc/apache2/apache2.conf |grep -E "^<Directory" |tail -2|grep -o '<.*\>' |cut -d " " -f2|head -1)
DOSSIERWEB2=$(cat /etc/apache2/apache2.conf |grep -E "^<Directory" |tail -2|grep -o '<.*\>' |cut -d " " -f2|tail -1) #récupération du dossier d'apache2 ou on peut mettre des pages WEB

touch $DOSSIERWEB2/html/ping_me.html # creation d'un nouveau fichier qui sera une page web
echo "michonne" >  $DOSSIERWEB2/html/ping_me.html # mettre le mot dans le fichier cree ci dessus
if [ "$(curl -s http://$IPSERV/ping_me.html)" = "michonne" ] #recupération du contenu de la page avec la commande curl et fait la comparaison avec le mot désiré
 then HTTP_STATE="OK"
 else HTTP_STATE="ERROR"
 fi
 }
 #______________________________________________Test installation PHPMYADMIN______________________________________________________________________
 
 Test_Installation_PhpMyAdmin () {
IPSERV=$(ifconfig eth0 | grep 'inet adr'|cut -d ":" -f2|cut -d" " -f1) # Récupération de l'adresse ip de la machine
 if [ "$(curl -s http://$IPSERV/phpmyadmin|grep -o 'The document has moved')" = "The document has moved" ] #recupération du contenu de la page avec la commande curl et fait la comparaison avec le mot désiré
 then PHPMYADMIN_STATE="Ok"
 else PHPMYADMIN_STATE="ERROR"
 fi
 }
 
 #________________________________________________Test installation MYSQL_______________________________________________________________
 
  Test_Installation_Mysql () {
 if [ "$(echo "show databases;" | mysql -u root --password=$MYSQL_PASSWD |grep -o mysql)" = "mysql" ] #connexion a la base de données,aprés on affiche tous les base de données existants et on vérifie si la base désiré existe parmi ces bases
 then MYSQL_STATE="OK"
 else MYSQL_STATE="ERROR"
 fi
 
 }
 #_______________________________________________Changement utilisateur et PID/GID________________________________________________________________
 
 Changer_User (){
CreationUser2 $APACHE_USER $U_GID_CARL #Creation de l'utilisateur carl avec uid 501
CreationUser2 $MYSQL_USER  $U_GID_BETH #Creation de l'utilisateur beth avec uid 500

 /etc/init.d/apache2 stop >> $chemin/logInstall
sed -i 's/export APACHE_RUN_USER='$HTTP_USER_CONF'/export APACHE_RUN_USER='$APACHE_USER'/g' /etc/apache2/envvars # on remplace l'utilisateu par défaut d'apache par l'utilisateur carl
sed -i 's/export APACHE_RUN_GROUP='$HTTP_USER_CONF'/export APACHE_RUN_GROUP='$APACHE_USER'/g' /etc/apache2/envvars # on remplace le groupe par défaut d'apache par le groupe carl
/etc/init.d/apache2 start >> $chemin/logInstall
/etc/init.d/mysql stop >> $chemin/logInstall
sed -i 's/\= '$MYSQL_USER_CONF'/\= '$MYSQL_USER'/g' /etc/mysql/my.cnf #on remplace l'utilisateur par défaut de mysql par l'utilisateur beth
chown -R $MYSQL_USER:$MYSQL_USER /var/run/mysqld/ #on change le propriétaire de ce répertoire et ses sous-repertoire à l'utilisateur beth avec la commande chown
chown -R $MYSQL_USER:$MYSQL_USER /var/lib/mysql/* #on change le propriétaire de ce répertoire et ses sous-repertoire à l'utilisateur beth avec la commande chown
chown -R $MYSQL_USER:$MYSQL_USER /var/lib/mysql/  #on change le propriétaire de ce répertoire et ses sous-repertoire à l'utilisateur beth avec la commande chown
/etc/init.d/mysql start >> $chemin/logInstall
 }
