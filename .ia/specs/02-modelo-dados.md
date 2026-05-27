# 02 — Modelo de dados

## Convenções gerais

- **PK**: UUID v7 em toda entidade sincronizável (gerável tanto no client quanto no server)
- **Timestamps**: `created_at` e `updated_at` em UTC; exibição converte para `America/Sao_Paulo`
- **Soft-delete**: `deleted_at` (timestamp; `NULL` = não deletado) em toda tabela sincronizável — necessário para propagar deleção via tombstone
- **Lock otimista**: `version` (integer, incrementado a cada update) em toda tabela sincronizável

## Diagrama ER (texto)

```
users ──< attendances >── matches
                            │
                            └─< match_stats >── users
```

> **Sorteio de times, cronômetro e placar não têm tabelas** — são ferramentas temporárias em memória no app do admin durante a partida, e descartadas ao final. Gols/assistências registrados pelo admin no fim do jogo persistem em `match_stats`.

## Schema Postgres (server)

### `users`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid (v7) | PK |
| `email` | citext | unique, not null |
| `name` | string | not null |
| `phone` | string | opcional, E.164 |
| `role` | enum (`admin`, `player`) | not null, default `player` |
| `player_type` | enum (`monthly`, `casual`) | label organizacional (mensalista/avulso); sem implicação financeira no MVP; default `casual` |
| `skill_level` | integer (1–5) | usado no sorteio; default 3 |
| `preferred_position` | enum (`goalkeeper`, `defender`, `midfielder`, `forward`, `any`) | default `any` |
| `encrypted_password`, etc. | (campos do Devise) | — |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `email` (unique), `(deleted_at, updated_at)` para pull.

### `matches`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `scheduled_at` | timestamp | data + hora do racha (UTC); sempre uma segunda-feira no MVP |
| `max_players` | integer | default 14 |
| `status` | enum (`scheduled`, `in_progress`, `finished`, `canceled`) | not null |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `scheduled_at`, `(deleted_at, updated_at)`.

> **Local e dia da semana são fixos no MVP**. O nome da quadra e o horário padrão ficam em **config do servidor** (`config/club.yml`, lidos por `Rails.application.config.club.*`) e expostos via endpoint `GET /api/v1/club` para o app consumir. Um Sidekiq cron job (`Matches::CreateWeeklyJob`) roda toda segunda de manhã criando o `Match` daquela semana se ele ainda não existir. Se um dia o local mudar para um racha específico, adicionar uma coluna `location_override` — não está no MVP.

### `attendances`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK users |
| `match_id` | uuid | FK matches |
| `status` | enum (`confirmed`, `declined`, `pending`) | not null, default `pending` |
| `waitlist_position` | integer | `NULL` se confirmado dentro do limite; > 0 = ordem na espera |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `(user_id, match_id)` unique parcial onde `deleted_at IS NULL`; `match_id`.

### `match_stats`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `match_id` | uuid | FK matches |
| `user_id` | uuid | FK users |
| `goals` | integer | default 0 |
| `assists` | integer | default 0 |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | — |

Índices: `(match_id, user_id)` unique parcial.

## Schema local Flutter (Drift)

Espelha as tabelas sincronizáveis (mesmas colunas e tipos, exceto `encrypted_password` que **não** vai para o client) e adiciona:

### `sync_queue`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | text (uuid v7) | PK |
| `entity` | text | `'users'`, `'matches'`, etc. |
| `entity_id` | text (uuid) | ID do registro afetado |
| `operation` | text (`create`, `update`, `delete`) | — |
| `mutation_id` | text (uuid v7) | enviado ao server para idempotência |
| `payload_json` | text | corpo da mutação |
| `created_at` | datetime | — |
| `attempts` | integer | quantas tentativas já fizemos |
| `last_error` | text | erro da última tentativa (se houver) |

### `sync_state`

| Coluna | Tipo | Notas |
|---|---|---|
| `entity` | text | PK |
| `last_synced_at` | datetime | cursor de pull |

## Convenções de ID

- IDs são UUID v7 → ordenáveis temporalmente, sem colisão entre client/server
- Gerados pelo client quando a entidade nasce local; o server aceita o ID enviado
- Nunca há "ID temporário → ID real": o ID criado offline é o ID final

## Convenções de soft-delete e tombstone

- `deleted_at` marca o registro como deletado para o domínio
- Sync envia o registro com `deleted_at` setado → outros clients aplicam a deleção
- Job `Sync::CleanupTombstonesJob` apaga fisicamente registros com `deleted_at` há mais de 90 dias

## Quando pagamentos voltarem

Reservar nomes/conceitos para evitar refator amplo:
- Tabelas futuras prováveis: `subscriptions`, `payments`, `expenses`, `webhook_events`
- Coluna provável em `attendances`: `paid_amount_cents` (avulso)
- Adicionar `payment_gateway` lib no Rails como interface abstrata
