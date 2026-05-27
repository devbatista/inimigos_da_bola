# 03 — Sincronização offline-first

## Princípio

A UI lê do **DB local** (Drift) via streams reativas. A maior parte das escritas é aplicada localmente primeiro (otimista) e enfileirada em `sync_queue`. Um **sync engine** roda em background drenando a fila para o Rails e puxando atualizações do server. Em quadras com 4G ruim ou sem rede, o app continua usável para leitura, sorteio, cronômetro, placar e lançamento de stats; ao reconectar, tudo que é offline-first se reconcilia.

**Exceção importante**: confirmação/cancelamento de presença do próprio player não é offline-first. O app precisa enviar imediatamente ao backend para garantir lista de espera, limite de vagas e promoção correta. Sem rede, o botão deve informar que a ação precisa de conexão e não deve gravar uma presença pendente local.

**Presença avulsa do admin** também exige rede, mas não faz parte do fluxo obrigatório de presença do player. Ela acontece em tela separada de admin, por endpoint próprio.

## Modelo de sync

**Delta sync com last-write-wins (LWW) por timestamp do server**.

- "Delta" porque o pull traz apenas o que mudou desde o último cursor (`sync_state.last_synced_at`)
- "LWW" porque, em conflito, o registro com `updated_at` mais recente vence
- Justificativa: baixa concorrência (1 admin, ~20 jogadores), single-tenant, sem necessidade de merge fino. CRDTs são overkill no MVP.

## Fluxo online obrigatório: presença do próprio player

```
[UI "Vou!" / "Não vou"]
  │
  ▼
[AttendanceRepository]
  ├─ verifica conectividade/token
  ├─ envia imediatamente: POST /api/v1/weekly_sessions/:id/attendances
  ├─ em sucesso: grava resposta no Drift e atualiza listas locais
  └─ sem rede/erro: não altera presença local; mostra mensagem de ação não concluída
```

Regras:
- Não inserir confirmação/cancelamento de presença do próprio player em `sync_queue`.
- Não fazer update otimista de `attendances`; o server decide confirmação, lista de espera e promoção.
- Após sucesso, o backend pode disparar push silencioso para outros devices puxarem atualização.
- Em falha de rede, manter o estado anterior visível no cache e orientar o usuário a tentar novamente.

## Fluxo online separado: presença avulsa do admin

```
[Tela admin "Confirmações avulsas"]
  │
  ▼
[GuestAttendanceRepository]
  ├─ verifica conectividade/token e permissão de admin
  ├─ adiciona avulso: POST /api/v1/weekly_sessions/:id/guest_attendances
  ├─ remove avulso: DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id
  ├─ em sucesso: grava resposta no Drift e atualiza contador/listas locais
  └─ sem rede/erro: não altera presença local; mostra mensagem de ação não concluída
```

Regras:
- Não inserir presença avulsa em `sync_queue`.
- Não reutilizar o botão "Vou!" / "Não vou" para avulsos.
- Presença avulsa só é criada/removida pela tela separada de admin.
- O server decide se a presença avulsa entra como confirmada ou lista de espera.

## Fluxo de push offline-first (mutações locais → server)

Esse fluxo **não** se aplica a `attendances`. Presença do próprio player e presença avulsa do admin usam chamadas online imediatas e atualizam o Drift somente após resposta do backend.

```
[UI ação]
  │
  ▼
[Repository]
  ├─ aplica mutação no DB local (otimista)
  └─ insere row em sync_queue (mutation_id = uuid v7)
       │
       ▼
[Sync Engine]
  ├─ drena sync_queue em FIFO por entity
  ├─ envia ao server: POST /api/v1/sync/<entity> { mutation_id, op, payload }
  ├─ em sucesso: remove da fila
  ├─ em conflito (409): aplica LWW pelo updated_at do server, remove da fila
  └─ em erro de rede: incrementa attempts, backoff exponencial (1s, 2s, 4s, ...)
```

### Idempotência

- Cada mutação enviada carrega um `mutation_id` (UUID v7)
- Server mantém tabela `processed_mutations(mutation_id PRIMARY KEY, applied_at)` ou usa um cache de curto prazo (Redis com TTL)
- Ao receber a mesma `mutation_id` de novo (retry duplicado), retorna 200 sem aplicar — fluxo é seguro

### Backoff e limite

- Backoff exponencial com jitter, capado em 5 min
- Após 10 tentativas falhas seguidas, marca a mutação como **suspended** (`last_error` preenchido) e exibe ícone na tela de Status; admin pode forçar reenvio ou descartar

## Fluxo de pull (server → local)

```
GET /api/v1/sync?since=<iso8601>&entities=users,weekly_sessions,attendances,session_stats

Resposta:
{
  "server_time": "2026-05-26T20:15:00Z",
  "entities": {
    "users":       [ { ...record, updated_at, deleted_at }, ... ],
    "weekly_sessions": [ ... ],
    "attendances": [ ... ],
    "session_stats": [ ... ]
  }
}
```

> Partidas curtas, sorteio de times, cronômetro e placar **não sincronizam** — são estado em memória no app (Riverpod), descartado ao sair da tela ou fechar o app. A sessão semanal sincroniza presença e estatísticas agregadas, mas não salva times sorteados nem placar de cada partida curta.

> Avaliações de habilidade (`skill_ratings`) têm regra de privacidade: o client pode enviar/criar/atualizar apenas as notas dadas pelo usuário logado, mas o pull não retorna avaliações individuais de outros usuários. A média (`users.skill_score`) é calculada pelo server; a UI exibe apenas o `skill_score` do usuário logado na tela principal, sem mostrar médias de outros players.

- Sync engine itera cada entity e faz upsert no Drift por `id`
- Registros com `deleted_at` preenchido são tombstones → DAO marca como deletado localmente (ou apaga, dependendo da policy)
- Após processar tudo, atualiza `sync_state.last_synced_at = response.server_time`

## Gatilhos de sync

1. **App abre** (cold start) — pull primeiro, depois drena push pendente
2. **Reconexão de rede** — escutar `connectivity_plus`; ao mudar para online, dispara
3. **Background periódico** — `workmanager` a cada 30 min
4. **Push silencioso (FCM data message)** — quando o server quer empurrar atualização imediata (ex.: alguém confirmou presença)
5. **Pull manual** — tela tem um pull-to-refresh

## Resolução de conflitos (LWW)

Quando o server retorna 409 ou quando o pull traz uma versão mais recente que a local:

1. Comparar `updated_at` do registro local vs do server
2. Vence o de `updated_at` maior
3. Se vence o server, sobrescreve o local; se vence o local, mantém local e reenfileira o push
4. Para campos individuais (LWW por campo), o server retorna o registro inteiro; aceitamos o "todo" — refinamento por campo fica como evolução futura

## Autenticação offline

- JWT (access + refresh) em `flutter_secure_storage`
- App abre sem rede: lê token do storage, valida expiração local (assinatura não verificável offline, mas exp sim)
- Se access token expirou: UI continua funcional (lendo cache); ao tentar sincronizar, faz refresh
- Se refresh token também expirou: força logout ao reconectar

## O que não funciona offline (MVP atual)

- Login pela primeira vez (precisa rede)
- Reset de senha
- Aceitar convite via link mágico (primeira vez)
- Confirmar/cancelar presença
- Push notifications (FCM exige rede)

Fluxos offline-first no MVP: sortear time, usar cronômetro/placar, lançar gols/stats e cadastrar jogador pelo admin. Confirmação de presença é online obrigatória.

## Métricas de sync

Tela escondida em "Configurações → Status de sincronização" (útil para suporte da turma):

- Tamanho atual da `sync_queue`
- Idade da mutação mais antiga em fila
- Último sync bem-sucedido (timestamp)
- Última falha (com `last_error`)
- Botão "Forçar sync agora"
- Botão "Reenviar mutações suspensas"

## Contrato dos endpoints de sync

### `POST /api/v1/sync/{entity}` (push)

Headers: `Authorization: Bearer <jwt>`, `Idempotency-Key: <mutation_id>`

Body:
```json
{
  "op": "create" | "update" | "delete",
  "record": { "id": "...", "field": "value", "updated_at": "...", "version": 3 }
}
```

Respostas:
- `200 OK` — aplicado (ou já aplicado anteriormente por idempotency)
- `409 Conflict` — versão server é mais recente; corpo retorna o registro server
- `422 Unprocessable Entity` — payload inválido
- `401 Unauthorized` — token inválido/expirado

### `GET /api/v1/sync` (pull)

Query: `since=<iso8601>` (default = epoch), `entities=users,weekly_sessions,...` (default = todas)

Resposta: como descrito acima.

## Diretrizes de implementação no Flutter

- **Repository por feature** é o único caminho de leitura/escrita
- Repository expõe `Stream<T>` para reads (vem direto do Drift)
- Repository expõe `Future<void>` para writes; internamente: escreve no Drift + insere em `sync_queue` em uma transação atômica
- Exceção: `AttendanceRepository` para confirmar/cancelar presença do próprio player e `GuestAttendanceRepository` para presença avulsa do admin chamam o backend imediatamente e só persistem no Drift após resposta
- Sync engine roda como **isolate de fundo** (`flutter_isolate` ou similar) para não travar a UI
- Erros de sync não viram exceptions para a UI — viram entries de log/telemetria
