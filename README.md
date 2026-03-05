# Mattermesh

Mattermesh est une base communautaire **non-enterprise** autour de Mattermost.

Objectif actuel:
- rester sur une build Team/non-enterprise
- conserver une base simple auto-hebergee
- retirer les dependances/pieces enterprise
- appliquer uniquement un patch de limite utilisateurs

Etat du projet:
- experimental
- non pret pour production
- contributions bienvenues

## Ce que contient ce repo

- `Dockerfile`: build Mattermost en mode `BUILD_ENTERPRISE=false`
- `docker-compose.yml`: stack locale (Mattermesh + PostgreSQL)
- `patches/mattermesh-nolimituserpatch.patch`: patch limites utilisateurs

## Lancement

```bash
docker compose build --no-cache
docker compose up -d
```

Puis ouvrir `http://localhost:8065`.

## Important

Ce repo ne doit pas reintroduire de mecanismes enterprise.
Si une contribution ajoute un couplage enterprise/licence, elle devra etre refusee.
