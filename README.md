# Debian-CONFIGURATION-ENTREPRISE
# Projet Kiosque d'Enregistrement : Debian Client & API Windows

Ce document centralise l'architecture, les pré-requis et les missions de développement pour le déploiement automatisé de machines virtuelles Debian sécurisées.

## 1. Architecture Globale
* **Client (VM Debian) :** Application kiosque développée en C++ (Qt) qui bloque l'environnement de bureau au démarrage pour forcer la saisie du formulaire d'inscription.
* **Serveur (Hôte Windows) :** API REST (ex: C# ASP.NET Core) qui réceptionne les requêtes d'inscription et fournit un tableau de bord à l'administrateur pour modération.
* **Déploiement (VM Debian) :** Scripts système locaux s'exécutant en arrière-plan pour interroger l'API et appliquer physiquement les configurations sur le système Linux une fois l'approbation reçue.

## 2. Objectifs de Développement des Scripts
Cette section détaille la logique attendue pour les scripts d'automatisation. L'objectif est de te permettre de cibler tes recherches pour concevoir ces outils en toute autonomie (en Bash ou en Python).

### Phase A : Communication avec l'API (Polling)
**Mission :** Créer un service d'arrière-plan qui vérifie en boucle si l'administrateur a validé la demande de l'utilisateur.
* **Concepts à rechercher et maîtriser :**
  * Création d'une boucle infinie avec une temporisation pour ne pas surcharger le réseau (ex: pause de 10 secondes entre chaque cycle).
  * Exécution de requêtes HTTP `GET` en ligne de commande pour interroger l'API (rechercher l'outil `curl` sous Linux ou la bibliothèque `requests` en Python).
  * Extraction et analyse d'une réponse au format JSON pour isoler le statut de la requête (rechercher l'outil `jq` pour les scripts Bash).

### Phase B : Provisioning (Création du compte système)
**Mission :** Générer le profil utilisateur définitif à partir des données validées récupérées sur l'API.
* **Concepts à rechercher et maîtriser :**
  * Création d'un nouvel utilisateur système avec génération automatique de son répertoire personnel `/home` (commande `useradd`).
  * Attribution d'un mot de passe en mode non-interactif (rechercher le fonctionnement de `chpasswd`).
  * Gestion des groupes Linux pour octroyer ou restreindre les droits d'administration (groupe `wheel`).

### Phase C : Personnalisation et Nettoyage
**Mission :** Appliquer les choix esthétiques, installer les logiciels demandés, puis verrouiller la VM pour son utilisation finale.
* **Concepts à rechercher et maîtriser :**
  * Installation silencieuse de paquets via le gestionnaire de Debian (commande `apt`).
  * Manipulation de fichiers ou exécution de commandes pour modifier le thème (KDE/Cinnamon) depuis un script.
  * Suppression totale et propre du compte temporaire qui a servi à la configuration initiale (commande `userdel`).
  * Déclenchement d'un redémarrage automatique du système pour afficher l'écran de connexion standard.

## 3. Modèle de Données API (Référence)

| Champ | Type | Obligatoire | Description |
| :--- | :--- | :--- | :--- |
| `NomPrenom` | Chaîne | Oui | Identité complète de l'utilisateur. |
| `Email` | Chaîne | Oui | Adresse de contact. |
| `Identifiant` | Chaîne | Oui | Nom du compte local Linux (sans espaces ni caractères spéciaux). |
| `MotDePasse` | Chaîne | Oui | Mot de passe de session. |
| `Theme` | Chaîne | Non | Préférence visuelle (ex: Clair/Sombre). |
| `Statut` | Chaîne | Oui | Valeurs de contrôle API : `EnAttente`, `Valide`, `Refuse`. |

## 4. Évolutions Futures
* **Supervision :** Intégration d'un agent de prise en main à distance silencieux s'exécutant en tâche de fond.
* **Télémétrie :** Remontée des statistiques de performance (charge CPU, occupation RAM) vers le serveur Windows.
