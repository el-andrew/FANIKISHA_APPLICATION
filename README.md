# Fanikisha

**Level up your saving habit.** Fanikisha ("make it succeed" in Swahili) helps
owners of small and medium businesses in Tanzania save towards goals such as
new stock, equipment or rent. Every deposit is split across the owner's goals
automatically, weighted by each goal's priority and how close its deadline is.

| Dashboard | Save money | Goal |
| --- | --- | --- |
| ![](docs/screenshots/dashboard.png) | ![](docs/screenshots/save-money.png) | ![](docs/screenshots/goal-detail.png) |

Fanikisha began in 2022 as a training project and has been rebuilt from the
ground up: a NestJS API with PostgreSQL, and a Flutter app. See the
[roadmap](docs/ROADMAP.md) for what's done and what's next.

## Repository layout

| Path | What it is |
| --- | --- |
| [`api/`](api/) | Backend: NestJS 12, PostgreSQL, Prisma. [Setup and API reference](api/README.md) |
| [`mobile/`](mobile/) | Mobile app: Flutter, Riverpod, go_router; English and Kiswahili. [Setup and architecture](mobile/README.md) |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Rebuild plan and progress |
