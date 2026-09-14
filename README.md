# gouv-orga

Outil expérimental de visualisation d'organigrammes de l'administration française, construit à partir des données ouvertes de l'[API Annuaire du service-public](https://api-lannuaire.service-public.gouv.fr/).

> **Statut : en développement** — projet exploratoire, non officiel.

## Ce que ça fait

- **Recherche** d'un organisme public (ministère, direction, service…) via l'API Annuaire
- **Construction automatique** de l'arbre hiérarchique en suivant les liens parent/enfant de l'API
- **Deux modes de rendu** :
  - **HTML/CSS** pour les petits organigrammes (< seuil configurable)
  - **D3 interactif** (zoom, pan, expand/collapse) pour les grands organigrammes
- **Informations affichées** au choix : responsable, téléphone, adresse, formulaire de contact, SIREN, réseaux sociaux
- **Filtrage par catégorie** : service interministériel, national, régional, départemental, local
- **Export** : JSON, CSV, PNG, SVG, impression PDF (A4/A3, portrait/paysage)

## Comment ça marche

L'application est une page statique (HTML + CSS + JS) sans framework ni build. Elle interroge directement l'API Annuaire du service-public en REST.

1. L'utilisateur recherche un organisme — l'autocomplétion interroge l'API avec `suggest()`
2. Au clic sur "Générer", un parcours BFS récursif charge l'entité racine puis ses enfants niveau par niveau, jusqu'à la profondeur max choisie
3. Selon le nombre de noeuds, le rendu bascule en mode HTML (arbre CSS flex) ou D3 ([d3-org-chart](https://github.com/nicedash/d3-org-chart))

### Stack

| Composant | Détail |
|-----------|--------|
| Interface | [DSFR](https://www.systeme-de-design.gouv.fr/) (Design System de l'État) |
| Graphe D3 | [d3-org-chart](https://github.com/nicedash/d3-org-chart) + [d3-flextree](https://github.com/nicedash/d3-flextree) |
| Données | [API Annuaire service-public.gouv.fr](https://api-lannuaire.service-public.gouv.fr/) |
| Hébergement | GitHub Pages |

## Source GRIST

En alternative à l'API Annuaire, l'organigramme peut être construit depuis une table GRIST
(colonnes attendues : `Nom`, `Parent` (Ref, `0` pour la racine), `AncienNom`, `Responsable`,
`Fonction`, `Telephone`, `Adresse`, `Contact`, `Siren`, `Reseaux`).

**ID du document** — c'est le segment qui suit `/o/<org>/` dans l'URL GRIST, sans le nom lisible :

```
https://grist.numerique.gouv.fr/o/docs/pUc8X9tNGAt7/Tests-organigrammes-automatiques
                                        ^^^^^^^^^^^^ ID du document
```

**Accès API** — les appels partent du navigateur ; trois modes au choix :

| Mode | URL appelée | Quand l'utiliser |
|------|-------------|------------------|
| **Direct** (défaut) | `https://grist.…/api/docs/…` | Le serveur GRIST autorise le CORS pour les appels porteurs d'une clé API |
| **Proxy local** | `/grist-gouv/api/docs/…` | Déploiement nginx/Docker : même origine, donc ni CORS ni preflight (voir `nginx.conf`) |
| **Proxy Charts Builder** | `https://chartsbuilder.matge.com/grist-gouv-proxy/…` | Secours historique |

Le mode « Proxy local » n'existe que sur le déploiement nginx, avec une cible figée par route
(`/grist-gouv/` → `grist.numerique.gouv.fr`, `/grist-saas/` → `docs.getgrist.com`) pour ne pas
exposer un relais ouvert. Un serveur auto-hébergé retombe toujours sur l'appel direct : à lui
d'autoriser l'origine de la page.

## Lancer en local

Ouvrir `index.html` dans un navigateur, ou servir avec n'importe quel serveur statique :

```sh
npx serve .
```

Aucune dépendance à installer — tout est chargé via CDN.

## Déploiement

Deux cibles :

- **GitHub Pages** — le push sur `main` déclenche automatiquement le déploiement via l'action `.github/workflows/deploy-pages.yml`.
- **Lab VibeLab (Docker)** — page statique servie par nginx, conteneurisée pour le lab `lab.miweb.run` :

  ```sh
  # build + run local
  docker build -t gouv-chart .
  docker run --rm -p 8080:80 gouv-chart   # http://localhost:8080

  # déploiement sur le lab via spawn
  ssh vps "spawn up gouv-chart git@github.com:bmatge/gouv-chart.git"
  # → https://gouv-chart.lab.miweb.run
  ```

  Le `docker-compose.yml` respecte le contrat spawn (réseau `proxy`, labels Traefik, port interne 80).

## Limites connues

- L'API Annuaire est interrogée séquentiellement par lots de 20 entités — les organigrammes très profonds ou très larges peuvent être lents à charger
- Le rendu HTML/CSS n'est pas optimisé pour les arbres de plus de ~50 noeuds
- Les données dépendent de la complétude de l'API Annuaire (certains organismes n'ont pas de liens hiérarchiques renseignés)
