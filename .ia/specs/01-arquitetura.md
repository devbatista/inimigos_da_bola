# 01 — Arquitetura

## Pilar: Offline-first

A UI **sempre** lê do banco local (Drift/SQLite). Mutações são aplicadas localmente de forma otimista e enfileiradas para sincronização. O server é a fonte de verdade que reconcilia. Isso vale para todas as features do MVP (leitura e escrita) — não há, no escopo atual, nenhum fluxo online-only.

Detalhes em [03-sincronizacao-offline.md](03-sincronizacao-offline.md).

## Diagrama de alto nível

```
┌──────────────────────────────────────┐         ┌──────────────────────────────┐
│            Flutter App               │         │       Rails API (v1)         │
│                                      │         │                              │
│  Widgets / Screens (Riverpod)        │         │  Controllers (api/v1/*)      │
│        │                             │         │        │                     │
│        ▼ (Stream<T>)                 │         │        ▼                     │
│  Repositories ◄───┐                  │   HTTP  │  Services (regras de negócio)│
│        │          │                  │  JSON   │        │                     │
│        ▼          │                  │ ◄─────► │        ▼                     │
│  Drift (SQLite)   │                  │  JWT    │  Models (AR) ── Postgres     │
│        ▲          │                  │         │        │                     │
│        │          ▼                  │         │        ▼                     │
│  ┌─────────────────────────┐         │         │  Sidekiq Jobs                │
│  │   Sync Engine           │         │         │        │                     │
│  │  - sync_queue (push)    │         │         │        ▼                     │
│  │  - delta pull           │ ──────► │ ──────► │  FCM (push)                  │
│  │  - LWW conflict         │         │         │                              │
│  └─────────────────────────┘         │         │                              │
└──────────────────────────────────────┘         └──────────────────────────────┘
            ▲                                              │
            │  push silencioso "data message" (trigger)    │
            └──────────────────────────────────────────────┘
                              FCM
```

## Camadas — Flutter

```
lib/
├── core/
│   ├── db/          # Drift (database, DAOs, migrations)
│   ├── sync/        # sync engine (push, pull, conflict resolution)
│   ├── theme/       # ThemeData + tokens de design (ver 06-design-ui.md)
│   ├── api/         # http client (Dio) + interceptors (auth, retry, logging)
│   ├── auth/        # session manager, token storage (flutter_secure_storage)
│   └── time/        # clock injetável (testabilidade) + tz America/Sao_Paulo
├── features/
│   ├── players/
│   │   ├── data/         # repositories (escrevem em Drift + enfileiram sync)
│   │   ├── domain/       # models (freezed), value objects
│   │   └── presentation/ # screens, widgets, riverpod providers
│   ├── attendance/
│   ├── teams/            # sorteio (algoritmo client-side, sem persistência)
│   ├── game_mode/        # cronômetro + placar (estado em memória)
│   └── stats/            # gols, assistências, ranking
└── main.dart
```

**Regra invariável**: nenhuma tela ou provider lê da API diretamente. Sempre via repository, e o repository sempre lê do Drift. A camada de sync é a única que fala HTTP. Isso garante que tudo é offline-first por padrão.

### State management
**Riverpod** (v2+). Justificativa:
- Providers reativos casam bem com `Stream<T>` do Drift
- Sem `BuildContext` para acessar state → mais testável
- Code generation com `riverpod_generator` reduz boilerplate

### Banco local
**Drift** (SQLite tipado). Justificativa:
- Queries reativas (`Stream<List<T>>`) que disparam ao mudar dados → UI atualiza sozinha
- Migrations versionadas
- Codegen tipado (DAOs, tabelas, queries compiladas)
- SQL real quando precisar (sorteio, agregações de stats)

## Camadas — Rails

```
app/
├── controllers/
│   └── api/v1/
│       ├── matches_controller.rb
│       ├── attendances_controller.rb
│       ├── teams_controller.rb
│       ├── stats_controller.rb
│       └── sync_controller.rb         # GET /api/v1/sync (pull) + endpoints de upsert
├── services/                          # regras de negócio (uma classe por caso de uso)
│   ├── attendance/confirm.rb
│   ├── matches/create_weekly.rb
│   └── sync/apply_mutation.rb
├── models/                            # ActiveRecord (validações estruturais e escopos)
├── serializers/                       # Blueprinter ou jsonapi-serializer
├── jobs/                              # Sidekiq
│   ├── matches/create_weekly_job.rb   # cron: cria o Match da semana toda segunda
│   ├── sync/cleanup_tombstones_job.rb
│   └── notifications/push_job.rb
├── policies/                          # Pundit (autorização por recurso)
└── config/
    └── club.yml                       # local fixo, horário do racha, dia da semana
```

**Regras**:
- Controllers magros: parsing/serialização e chamada do service correspondente
- Services: ponto único da regra de negócio; retornam resultado tipado (`Success` / `Failure`)
- Models: validações estruturais (presença, formato), escopos, callbacks **somente** para `updated_at`
- **Config do clube** (`config/club.yml`) é a fonte única de verdade para local da quadra, dia da semana e horário do racha. Não há entidade no banco para isso; é hardcoded no deploy. Endpoint `GET /api/v1/club` expõe esses valores para o app sincronizar e exibir.

## API

- Versionada: `/api/v1/...`
- Formato: JSON, envelope de erro padrão `{ "error": { "code": "ATTENDANCE_LIMIT", "message": "..." } }`
- Auth: JWT no header `Authorization: Bearer <token>`
- IDs: UUID v7 em todas as entidades sincronizáveis
- Timestamps: ISO-8601 em UTC
- Endpoints de sync detalhados em [03-sincronizacao-offline.md](03-sincronizacao-offline.md)

## Auth

- **`devise-jwt`** no server: emite JWT no login, revoga via denylist
- **`flutter_secure_storage`** no client: armazena access + refresh token criptografados
- App abre **offline** com token expirado mostrando cache; ao reconectar, tenta refresh
- Detalhes em [05-autenticacao.md](05-autenticacao.md)

## Deploy — alvo MVP

| Componente | Onde |
|---|---|
| Rails API | Railway ou Render (Docker + autoscale básico) |
| PostgreSQL | Postgres gerenciado do mesmo provedor |
| Redis (Sidekiq) | Add-on gerenciado |
| Sidekiq | Mesmo deploy do Rails (web + worker process) |
| App iOS | TestFlight (internal testing) |
| App Android | Internal track no Play Console |

## Observabilidade

- **Sentry** no Flutter (capturando inclusive falhas de sync com contexto: fila atual, último erro)
- **Logs estruturados** (JSON) no Rails via `lograge`
- **Métricas mínimas**: latência de endpoints, tamanho médio da fila de sync por usuário

## Decisões registradas

| Decisão | Alternativas consideradas | Por quê |
|---|---|---|
| Offline-first com Drift + sync engine | Cache simples (HTTP) | Quadras com rede ruim; admin precisa rodar sorteio e lançar stats sem rede |
| Riverpod | Bloc | Sintaxe mais enxuta, casa bem com Streams do Drift |
| UUID v7 | UUID v4 / int autoinc | Ordenação temporal natural + gerável no client sem colisão |
| LWW por timestamp do server | CRDTs / OT | Baixa concorrência (1 admin, ~20 jogadores); CRDT é overkill no MVP |
| Rails API only | Backend Node/Python | Preferência declarada do usuário; Rails brilha em CRUD + jobs |
| Pagamentos fora do MVP | Integrar Mercado Pago já | Reduz escopo e tempo até a turma usar o app; volta em sprint dedicada |
