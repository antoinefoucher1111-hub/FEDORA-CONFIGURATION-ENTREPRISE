# 🚀 Étude de Cas : Création d'une Solution Full-Stack de Provisioning Automatisé de VM Linux (Kiosque C++ Qt6 & API ASP.NET Core)

Je suis ravi de partager les détails d'un projet d'ingénierie système et de développement logiciel de bout en bout sur lequel j'ai travaillé récemment. L'objectif était de concevoir un système automatisé de configuration et de sécurisation de postes clients Linux (Debian) supervisé à distance depuis un hôte d'administration Windows.

Voici le retour d'expérience complet, l'architecture technique, et les étapes clés de cette réalisation.

---

## 💡 Le Défi & La Vision
Lorsqu'on distribue des machines virtuelles (VM) préconfigurées à des clients ou des collaborateurs, la gestion du premier démarrage est cruciale. Comment s'assurer que l'utilisateur configure correctement son profil tout en gardant le contrôle et la validation des accès ?

**La solution développée :**
Une machine virtuelle client (Debian) s'allume en mode **Kiosque ultra-sécurisé**. L'écran est verrouillé par une application graphique native qui force la saisie d'un formulaire d'inscription. Ces données sont envoyées à une **API REST sous Windows** qui les enregistre dans une base de données **SQLite**. L'administrateur, via un **tableau de bord Web**, examine la demande et valide (ou refuse) l'accès en temps réel. Dès validation, la machine cliente se déverrouille automatiquement.

---

## 🛠️ L'Architecture Globale du Système

Le projet repose sur une architecture client-serveur hybride et virtualisée :

```
       [ VM Cliente Debian ]                          [ Hôte Physique Windows ]
 ┌───────────────────────────────┐              ┌───────────────────────────────────┐
 │                               │   HTTP POST  │                                   │
 │  Kiosque Graphique (Qt6 C++)  ├─────────────►│   API REST C# (ASP.NET Core 8)    │
 │  - Saisie infos utilisateur   │              │                                   │
 │  - Verrouillage clavier/UI    │   HTTP GET   │  ┌─────────────────────────────┐  │
 │  - Polling de statut (2s)     │◄─────────────┤  │ Base de données SQLite     │  │
 │                               │              │  │ (Entity Framework Core)     │  │
 └───────────────────────────────┘              │  └─────────────────────────────┘  │
                                                │                 ▲                 │
                                                │                 │ Lecture / Écrit │
                                                │                 ▼                 │
                                                │  ┌─────────────────────────────┐  │
                                                │  │ Tableau de bord Admin Web   │  │
                                                │  │ (Bootstrap 5, JS Fetch)     │  │
                                                │  └─────────────────────────────┘  │
                                                └───────────────────────────────────┘
```

---

## 1. Le Client : Borne d'Enregistrement Sécurisée (Debian + C++ Qt6)
Pour garantir des performances optimales et une sécurité système imperméable, le client a été développé en **C++** avec le framework **Qt6** sur une distribution **Debian** installée de manière permanente.

### Caractéristiques majeures :
* **Mode Kiosque Strict :** L'application s'affiche en plein écran exclusif sans bordure (`Qt::FramelessWindowHint`) et reste systématiquement au-dessus de toutes les autres fenêtres (`Qt::WindowStaysOnTopHint`).
* **Verrouillage Clavier/UI :** Implémentation d'un filtre d'événements global (`eventFilter`) pour neutraliser toutes les tentatives d'échappement système (Alt+Tab, Alt+F4, Touche Windows/Super).
* **Vérification Réseau :** L'application teste la connectivité réseau vers l'API dès le démarrage. En cas d'absence de connexion, l'accès est bloqué avec une alerte visuelle.
* **Formulaire Riche & Personnalisé :** 
  * *Informations d'identité :* Nom, Prénom, Identifiant local souhaité, Mot de passe.
  * *Environnement :* Sélection du thème d'interface (Sombre/Clair) et du fond d'écran.
  * *Logiciels requis par catégorie :* Navigation Internet (Firefox/Chrome), Productivité (LibreOffice), Programmation (Git, IDEs).
  * *Privilèges :* Demande explicite des droits administrateur (`sudo`).
* **Polling de statut dynamique :** Dès la soumission, l'UI se verrouille et un composant `QTimer` interroge l'API Windows toutes les 2 secondes (`/api/Inscription/verifier/{identifiant}`). Si l'accès est "Approuvé", l'application affiche un écran de succès vert et libère la machine.

---

## 2. Le Serveur : API REST d'Administration (C# .NET 8 & EF Core 8)
Côté hôte Windows, l'API REST a été conçue pour être performante, modulaire et prête pour une mise en production.

### Points forts du Backend :
* **Modèle de données typé :** Définition d'un schéma C# clair représentant les profils utilisateurs et leurs préférences matérielles.
* **Persistance locale via SQLite :** Utilisation d'**Entity Framework Core** pour traduire instantanément les objets C# en requêtes SQL transactionnelles. L'historique complet est stocké de manière persistante dans un fichier `kiosque.db`.
* **Points de terminaison REST (Endpoints) :**
  * `POST /api/Inscription` : Réceptionne et valide la charge utile JSON envoyée par le kiosque.
  * `GET /api/Inscription` : Récupère la liste de tous les profils en BDD.
  * `PUT /api/Inscription/{id}/statut` : Permet à l'admin de mettre à jour le statut du dossier (`EnAttente`, `Approuvé`, `Refusé`).
  * `GET /api/Inscription/verifier/{identifiant}` : Utilisé par le client Qt pour son cycle d'interrogation.
* **Documentation OpenAPI (Swagger) :** Nettoyage des contrôleurs de test par défaut (suppression complète du template WeatherForecast) et personnalisation de Swagger avec des métadonnées professionnelles.

---

## 3. Le Frontend : Tableau de Bord de Supervision
Directement hébergée par l'API REST (via l'activation des fichiers statiques `UseStaticFiles`), l'interface d'administration offre un contrôle visuel élégant.

* **Interface moderne :** Conçue en **HTML5/Bootstrap 5** avec un rafraîchissement asynchrone régulier (toutes les 3 secondes via JavaScript et l'API `Fetch`).
* **Visualisation claire :** Un tableau dynamique présente l'état de chaque poste utilisateur sous forme de badges de couleur (`bg-warning`, `bg-success`, `bg-danger`).
* **Modération en un clic :** L'administrateur dispose de boutons d'action instantanés pour **Approuver** ou **Refuser** un profil. La mise à jour est immédiatement poussée dans la base SQLite, provoquant le déverrouillage de la VM Debian distante en moins de 2 secondes.

---

## ⚙️ Les Défis Réseau de la Virtualisation : Comment nous les avons résolus
L'un des défis les plus intéressants a été de faire communiquer la VM Debian avec l'hôte Windows dans un réseau virtuel fermé.

1. **Le routage IP VirtualBox vs VMware :** 
   * Sous VirtualBox en mode NAT, la passerelle hôte par défaut est `10.0.2.2`. 
   * Sous VMware, le NAT utilise un sous-réseau dynamique (généralement lié à la carte virtuelle `VMnet8`). Grâce à un diagnostic précis, nous avons identifié l'IP active de l'hôte Windows : `192.168.58.1`. Le code C++ a été reconfiguré pour cibler cette adresse spécifique sur le port `5000`.
2. **La sécurité de l'API (Kestrel) :** 
   * Par défaut, l'API ne répondait qu'à elle-même (`localhost`). Nous avons configuré l'URL d'application sur `0.0.0.0:5000` dans le fichier `launchSettings.json` et forcé l'écoute globale dans `Program.cs` via `app.Urls.Add("http://0.0.0.0:5000")`.
3. **Le Pare-feu Windows :** 
   * Pour autoriser le trafic entrant du réseau virtuel de VMware sur le port `5000`, nous avons appliqué une règle d'exclusion de sécurité ciblée en PowerShell administrateur :
   ```powershell
   New-NetFirewallRule -DisplayName "API Kiosque Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
   ```

---

## 📈 Perspectives et Évolutions Futures
Pour transformer ce prototype réussi en produit SaaS d'entreprise, les prochaines étapes prévues sont :
1. **Échanges bilatéraux et modération fine :** Permettre à l'administrateur de modifier à la volée les logiciels sélectionnés, d'ajouter des commentaires textuels ou de poser des questions à l'utilisateur directement depuis le tableau de bord web.
2. **Suivi d'activité (Télémétrie) :** Remontée automatique des métriques de performance de la machine cliente (charge CPU, utilisation de la RAM, espace disque) vers la console Windows.
3. **Prise en main silencieuse :** Intégration d'un agent de supervision transparent pour permettre à l'administrateur de visualiser l'écran et d'apporter un support à distance.

---

### 💡 Ce que je retiens de ce projet
Ce projet m'a permis d'allier des compétences en **développement bas niveau C++/Qt6**, en **architecture de services Web en C#**, et en **administration réseau de systèmes virtualisés**. Concevoir de bout en bout un pipeline où le clic sur un bouton d'un navigateur Windows contrôle la sécurité et l'état d'un poste Linux à travers un réseau virtuel a été une expérience extrêmement gratifiante !

N'hésitez pas à me poser des questions en commentaire ou à partager vos retours sur cette architecture !

---
**#SaaS #SystemsEngineering #Cpp #Qt6 #DotNet8 #CSharp #EFCore #SQLite #Virtualization #VMware #LinuxDebian #FullStackDeveloper #Cybersecurity**
