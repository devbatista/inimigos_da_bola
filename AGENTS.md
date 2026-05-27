# Inimigos da Bola

App mobile (Flutter) para gerir o "futebol de segunda" da turma: confirmação de presença semanal, sorteio de times equilibrados e estatísticas de partida. Single-tenant — atende um único grupo de ~10–20 jogadores.

> **Pagamentos / assinatura ficam fora do MVP.** Podem voltar como sprint dedicada no pós-MVP — quando voltarem, adicionar a spec `pagamentos.md` correspondente.

## Stack

- **Mobile**: Flutter (Dart) — offline-first, DB local Drift (SQLite), state via Riverpod
- **Backend**: Ruby on Rails (API only) + PostgreSQL
- **Auth**: `devise-jwt` + Pundit
- **Push/Notif**: Firebase Cloud Messaging (FCM)
- **Jobs**: Sidekiq

## Pilares (não negociáveis)

1. **Offline-first** — UI lê do DB local; sync engine reconcilia com o server em background. Detalhes em [.ia/specs/03-sincronizacao-offline.md](.ia/specs/03-sincronizacao-offline.md).
2. **Single-tenant** — sem `group_id`/`tenant_id` no schema do MVP.
3. **Código em inglês, UI em pt-BR** — identificadores, branches, commits, comentários em inglês; textos visíveis ao usuário em português.
4. **UUID v7** como PK de toda entidade sincronizável.
5. **Sem cores literais** nos widgets — sempre via tokens do design system ([06-design-ui.md](.ia/specs/06-design-ui.md)).

## Índice de specs (`.ia/specs/`)

| # | Arquivo | Quando ler |
|---|---|---|
| 00 | [visao-glossario.md](.ia/specs/00-visao-glossario.md) | Para entender o produto e o domínio |
| 01 | [arquitetura.md](.ia/specs/01-arquitetura.md) | Decisões de stack, camadas, deploy |
| 02 | [modelo-dados.md](.ia/specs/02-modelo-dados.md) | Schema Postgres + schema local Drift |
| 03 | [sincronizacao-offline.md](.ia/specs/03-sincronizacao-offline.md) | Antes de mexer em repository, sync engine ou endpoints `/sync` |
| 04 | [features.md](.ia/specs/04-features.md) | Detalhamento de cada funcionalidade + comportamento offline |
| 05 | [autenticacao.md](.ia/specs/05-autenticacao.md) | JWT, roles, sessão offline |
| 06 | [design-ui.md](.ia/specs/06-design-ui.md) | Paleta, tipografia, componentes |
| 07 | [convencoes.md](.ia/specs/07-convencoes.md) | Padrões de código Flutter + Rails |
| 08 | [roadmap.md](.ia/specs/08-roadmap.md) | Sprints e ordem de execução |

## Glossário rápido

- **Racha** — a partida de segunda-feira (sinônimo de "match")
- **Mensalista** — jogador rotulado como fixo (`player_type: monthly`). No MVP é só uma label organizacional; não há cobrança associada.
- **Avulso** — jogador rotulado como eventual (`player_type: casual`). Também só uma label no MVP.
- **Presença** — status do jogador para um racha: `confirmed` | `declined` | `pending`
- **Lista de espera** — confirmações além do `max_players` do racha
- **Ferramentas de quadra** — sorteio, cronômetro e placar. Disponíveis para qualquer usuário, vivem em memória (Riverpod), **não persistem**.
- **Admin** — organizador do racha (pode tudo); **Player** — jogador comum

## Comandos do projeto

*(placeholders — preencher após scaffolding no Sprint 0)*

```bash
# Mobile
flutter run                            # rodar em dispositivo/emulador
flutter test                           # testes
dart run build_runner build            # codegen (Drift, Riverpod, JSON)

# Backend
bundle exec rails s                    # servidor de dev
bundle exec rspec                      # testes
bundle exec sidekiq                    # worker
```

## Variáveis de ambiente (resumo)

- Mobile: `API_BASE_URL`, `FCM_SENDER_ID`
- Backend: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `FCM_SERVER_KEY`
