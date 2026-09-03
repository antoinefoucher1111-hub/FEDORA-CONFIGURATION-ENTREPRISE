#!/bin/bash

# Script de provisioning basé sur les données de l'API
# Version : 0.2.0

# Etape 0 : Installation de jq (si ce n'est pas déjà fait)
# (En tant que root, pas besoin de 'su')
dnf install -y jq

# ==========================

# Etape 1 : Réception et extraction des données du JSON

identifiant=$(jq -r '.Identifiant' sortie.json)
nom_prenom=$(jq -r '.NomPrenom' sortie.json)
password=$(jq -r '.MotDePasse' sortie.json)
service_user=$(jq -r '.Service' sortie.json) # Si le champ existe dans ton API
job_user=$(jq -r '.Job' sortie.json)         # Idem

echo "Création du compte pour : $nom_prenom (Login : $identifiant)"

# Création du profil utilisateur avec son répertoire personnel
useradd -m -s /bin/bash "$identifiant"

# Attribution du mot de passe de manière non-interacte (Phase B du sujet)
echo "$identifiant:$password" | chpasswd

# ==========================

# Etape 2 : Traçage / Documentation locale
cat << EOF > "/home/$identifiant/infos_compte.txt"
Nom complet : $nom_prenom
Login : $identifiant
Service : $service_user
Poste : $job_user
EOF


echo "Utilisateur $identifiant créé avec succès !"