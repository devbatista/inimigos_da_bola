# 02 — Modelo de dados

## Convenções gerais

- **PK**: UUID v7 em toda entidade sincronizável (gerável tanto no client quanto no server)
- **Timestamps**: `created_at` e `updated_at` em UTC; exibição converte para `America/Sao_Paulo`
- **Soft-delete**: `deleted_at` (timestamp; `NULL` = não deletado) em toda tabela sincronizável — necessário para propagar deleção via tombstone
- **Lock otimista**: `version` (integer, incrementado a cada update) em toda tabela sincronizável

## Diagrama ER (texto)

```
users ──< attendances >── weekly_sessions
  │                         │
  ├──< skill_ratings >── users
                            │
                            └─< session_stats >── users
```

> **Partidas curtas, sorteio de times, cronômetro e placar não têm tabelas** — são ferramentas temporárias em memória durante a quadra, e descartadas ao final. O racha pode ter várias partidas curtas de 8 minutos ou até 2 gols, com times mudando a cada rodada. Gols/assistências registrados no fim do racha persistem agregados em `session_stats`, vinculados à sessão semanal.

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
| `skill_score` | decimal(5,2) | média interna de habilidade (0–100), calculada pelo sistema a partir de `skill_ratings`; não editável pela UI e não exibida aos usuários |
| `goalkeeper` | boolean | indica se o player atua como goleiro; default `false` |
| `encrypted_password`, etc. | (campos do Devise) | — |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `email` (unique), `(deleted_at, updated_at)` para pull.

### `skill_ratings`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `evaluator_user_id` | uuid | FK users; quem deu a nota |
| `evaluated_user_id` | uuid | FK users; quem recebeu a nota |
| `score` | integer | nota de 0 a 100 |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `(evaluator_user_id, evaluated_user_id)` unique parcial onde `deleted_at IS NULL`; `evaluated_user_id`.

Regras:
- Um player avalia os demais players; autoavaliação não é permitida.
- Cada par avaliador/avaliado tem uma nota ativa. Reavaliar atualiza a nota existente, mas só é permitido após 1 mês da última avaliação desse par.
- Notas individuais nunca são exibidas para usuários.
- `users.skill_score` é recalculado pelo sistema como média das notas recebidas, limitado ao intervalo 0–100.
- A média também é privada: não aparece em lista de jogadores, perfil ou ranking; é usada apenas por regras internas, como balanceamento do sorteio.

### `weekly_sessions`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `scheduled_at` | timestamp | data + hora da sessão semanal do racha (UTC); sempre no dia definido por `RACHA_WEEKDAY` |
| `max_players` | integer | default 20 |
| `status` | enum (`scheduled`, `closed`, `canceled`) | not null |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `scheduled_at`, `(deleted_at, updated_at)`.

> **Data/dia recorrente, local e horário são fixos no MVP**. O dia recorrente, o nome da quadra e o horário padrão vêm de variáveis de ambiente do backend (`RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION`) e são expostos via endpoint `GET /api/v1/club` para o app consumir. Não há edição desses valores pela UI. Um Sidekiq cron job (`WeeklySessions::CreateCurrentJob`) cria a sessão semanal do racha com base nessa configuração se ela ainda não existir. Se um dia o local mudar para um racha específico, adicionar uma coluna `location_override` — não está no MVP.

### `attendances`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK users |
| `weekly_session_id` | uuid | FK weekly_sessions |
| `status` | enum (`confirmed`, `declined`, `pending`) | not null, default `pending` |
| `waitlist_position` | integer | `NULL` se confirmado dentro do limite; > 0 = ordem na espera |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | colunas de sync |

Índices: `(user_id, weekly_session_id)` unique parcial onde `deleted_at IS NULL`; `weekly_session_id`.

### `session_stats`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | uuid | PK |
| `weekly_session_id` | uuid | FK weekly_sessions |
| `user_id` | uuid | FK users |
| `goals` | integer | default 0 |
| `assists` | integer | default 0 |
| `created_at`, `updated_at`, `deleted_at`, `version` | — | — |

Índices: `(weekly_session_id, user_id)` unique parcial.

## Schema local Flutter (Drift)

Espelha as tabelas sincronizáveis (mesmas colunas e tipos, exceto `encrypted_password` que **não** vai para o client) e adiciona:

### `sync_queue`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | text (uuid v7) | PK |
| `entity` | text | `'users'`, `'weekly_sessions'`, etc. |
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
