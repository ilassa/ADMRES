#!/bin/bash
chemin=$(pwd)
source $chemin/install.conf
source $chemin/change.conf
source $chemin/funct.sh
echo "Installation en cours"
echo "veuillez patienter la fin de l'installation peut prendre quelques minutes"
echo "============================================================================="
#------------------------Initialisation system----------------------------------------------------------------------
Initialisation
echo "-------------------> Initialisation OK"
echo "============================================================================="
#-------------------------Installation-------------------------------------------------------------------------------
Installation
echo "-------------------> Installation OK"
echo "============================================================================="
#------------------------------------Test Installation-------------------------------------------------------------------------------
Test_Installation_Apache 
Test_Installation_PhpMyAdmin 
Test_Installation_Mysql 

echo "-----------------Verification Installation------------------------------------"
Recuperation_Donnee
Verification_Donnee_Or_changeUser 
echo "============================================================================="
#-------------------------------------Change User---------------------------------------------------------------------
 Changer_User 
echo "-------------------> Changement utilisateur OK"
echo "============================================================================="
#------------------------------------Test Installation 2-------------------------------------------------------------------------------
Test_Installation_Apache 
Test_Installation_PhpMyAdmin 
Test_Installation_Mysql 
 
echo "-----------------Verification changement utilisateur---------------------------"
Recuperation_Donnee
Verification_Donnee_Or_changeUser  

echo "============================Fin d'installation================================="
