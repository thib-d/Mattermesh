# Mattermesh

Mattermesh is an early-stage community project based on Mattermost.

Important note:
- we intentionally build from a non-enterprise baseline so patches can be applied and maintained with fewer conflicts
- this project does not claim to rewrite licensing terms
- if a legal expert wants to help review or propose a clean licensing path, contributions are very welcome

Current focus:
- implement SSO support through a dedicated patch
- remove restrictive user limits
- keep the setup simple with Docker Compose

Status:
- not production-ready
- looking for contributors

## Source Baseline

Mattermesh builds from:
- repository: `https://github.com/mattermost/mattermost`
- pinned commit: `e296a314bb93a318b66aec81353776b7d95aa04a`

## Included Patches

- `patches/mattermesh-sso.patch`
- `patches/mattermesh-nolimituserpatch.patch`

## Run

```bash
docker compose build --no-cache
docker compose up -d
```

Then open `http://localhost:8065`.

## Contributing

Contributions are welcome.
Please include:
- the exact upstream commit tested
- clear patch rationale
- reproducible validation steps
