# 08 — Roadmap

Sprints curtos focados em entregar valor incremental para a turma. Cada sprint termina com algo usável no app (mesmo que apenas pelo admin em modo dev).

> **Pagamentos / assinatura ficam fora deste roadmap MVP.** Quando voltarem, entram como sprint dedicado pós-MVP, com spec própria (`pagamentos.md`).

## Sprint 0 — Setup

- Scaffolding Flutter (estrutura `lib/core/*`, `lib/features/*`, `intl`, `riverpod_generator`, `freezed`, `drift`)
- Scaffolding Rails API (`--api`, Postgres, devise, devise-jwt, pundit, sidekiq, blueprinter, rspec)
- CI básico (GitHub Actions): lint + test em PR; deploy automático em `main` → staging
- Deploy "hello world" do Rails em Railway/Render
- App em iOS Simulator + Android Emulator com tela mostrando "Inimigos da Bola" estilizada (paleta do [06-design-ui.md](06-design-ui.md))
- Variáveis de ambiente `RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION` para data/dia recorrente, horário e local fixos; endpoint `GET /api/v1/club`

**Entrega**: dev pode rodar tudo localmente; staging up.

---

## Sprint 1 — Auth + Jogadores (offline-ready)

- Backend: `users` (com `role`, `player_type`, `skill_score`, `goalkeeper`), `skill_ratings`, endpoints de auth (sign_in, refresh, sign_out), convite (`invitations` + `accept_invitation`)
- Mobile: telas de login, convite (aceitar via deep link com seleção de `player_type`, `casual` pré-selecionado), perfil próprio
- Drift configurado com tabela `users` espelhada
- Repository `UserRepository` lê de Drift; primeiro `Stream<List<User>>` no app
- Sync engine **v0**: apenas push (mutações → server), sem pull ainda. Pull manual a cada login.
- Tela "Lista de jogadores" (admin) mostrando o que veio do server
- Fluxo de avaliação: players dão notas de 0 a 100 para os demais; reavaliação do mesmo player só após 1 mês; cada usuário vê o próprio `skill_score`, mas notas individuais e médias de outros players não aparecem na UI

**Entrega**: admin cadastra e convida jogadores; jogadores aceitam convite e fazem login. Tudo persiste local.

---

## Sprint 2 — Sync engine completo

- Endpoint `GET /api/v1/sync` (pull com `since` e `entities`)
- Endpoint `POST /api/v1/sync/{entity}` com idempotency-key (push)
- Sync engine: pull incremental, tombstones, LWW por `updated_at`
- Backoff exponencial com jitter, suspended after N attempts
- Tela "Status de sincronização" (escondida em settings) com métricas e botão de forçar sync
- Reconnect listener (`connectivity_plus`) que dispara sync
- Push silencioso FCM (data message) que dispara sync

**Entrega**: dois dispositivos com o mesmo grupo de jogadores reconciliam estado automaticamente.

---

## Sprint 3 — Sessão semanal + Confirmação de Presença

- Backend: `weekly_sessions`, `attendances`, job `WeeklySessions::CreateCurrentJob` (cron Sidekiq no dia configurado às 8h)
- Endpoints: `GET /api/v1/weekly_sessions/current`, `POST /api/v1/weekly_sessions/:id/attendances`, `POST /api/v1/weekly_sessions/:id/guest_attendances`
- Pundit policies (`WeeklySessionPolicy`, `AttendancePolicy`)
- Mobile: home com card do racha da semana, botão "Vou!"/"Não vou", contador público de confirmados, listas (confirmados/lista de espera/não vão/pendentes)
- Mobile admin: tela separada para adicionar/remover presença avulsa sem cadastro, atualizando o contador de confirmados
- Lógica de waitlist (promoção do primeiro da fila quando alguém cancela) — implementada server-side, refletida via sync
- Componente `AttendanceChip` e `PlayerTile` em `lib/core/widgets/`

**Entrega**: jogadores confirmam presença pelo app com envio imediato ao backend; admin vê quem vai estar lá. Leituras continuam via cache local, mas confirmação/cancelamento exige rede.

---

## Sprint 4 — Ferramentas de quadra (Sorteio + Cronômetro + Placar)

**Nenhuma persistência neste sprint** — tudo é estado in-memory (Riverpod `AutoDispose`), disponível para qualquer usuário logado.

- Mobile: tela "Ferramentas da quadra" como hub (3 acessos: Sorteio, Modo Jogo, voltar)
- **Sorteio**:
  - Algoritmo snake draft em `lib/features/teams/domain/draw_algorithm.dart` (função pura, testável)
  - Tela com participantes carregados automaticamente a partir dos confirmados do racha atual, adição local de avulso temporário não persistido, configuração de número de times, botão sortear, refazer, troca manual drag-and-drop, edição inline dos nomes
  - Sem endpoint, sem Drift; sorteio vale apenas uma vez/rodada e não é salvo
- **Modo Jogo** (cronômetro + placar fullscreen):
  - Placar grande (`Time A` / `Time B`, editáveis), botões `+`/`−`
  - Cronômetro progressivo ou regressivo (default 8 minutos), `Iniciar`/`Pausar`/`Resetar`, destaque quando um time chega a 2 gols
  - Wakelock ativo enquanto a tela está aberta
  - Continua contando matematicamente em background (recalcula ao voltar do background)
- Testes unitários do algoritmo (distribuição balanceada, respeito de goleiros) e do cronômetro (resiliência a background)

**Entrega**: qualquer usuário sorteia times e usa cronômetro+placar na quadra, sem rede, em modo standalone (sem broadcast entre celulares).

---

## Sprint 5 — Estatísticas

- Backend: `session_stats`, endpoint `POST /api/v1/weekly_sessions/:id/stats` (batch)
- Endpoint `GET /api/v1/stats/leaderboard?period=month|year`
- Mobile: tela "Lançar stats" (admin pós-jogo)
- Tela "Artilharia" com ranking
- Seção "Histórico" no perfil do jogador (sessões semanais participadas, gols, assistências)

**Entrega**: admin lança stats agregados no fim do racha (offline ok); ranking público atualiza.

---

## Sprint 6 — Notificações Push

- Backend: integração com FCM (gem `googleauth` + chamadas REST do FCM v1)
- Coluna `users.fcm_token`; endpoint `POST /api/v1/users/me/fcm_token`
- Notificações:
  - Todos: "Racha aberto" (segunda manhã, disparado pelo `WeeklySessions::CreateCurrentJob`)
  - Todos: "Lembrete: jogo em 1h" (job cron)
  - Player: "Abriu vaga! Você está confirmado" (quando promovido da lista de espera)
  - Admin: nova confirmação, cancelamento de presença e alteração de presença avulsa
  - Sync silencioso (data message) em mudanças relevantes
- Mobile: setup de FCM (firebase_messaging), permissão, background handler que dispara sync
- Telemetria mínima: log de entregas e clicks

**Entrega**: jogadores e admin recebem lembretes e avisos relevantes sem o admin precisar mandar áudio no WhatsApp.

---

## Sprint 7 — Polimento + lançamento na turma

- Bugs e ajustes finos coletados durante uso interno
- Tela "Sobre" com versão, link de suporte
- Configurações: editar próprio perfil, mudar foto (avatar), logout
- Telemetria/Sentry ligado em produção
- Build de produção: TestFlight + Internal Track Play Store
- Onboarding mínimo na primeira abertura (3 telas)

**Entrega**: app instalado em todos os celulares da turma; admin para de usar planilha.

---

## Pós-MVP (não priorizado)

- **Pagamentos / assinatura** (cartão recorrente, Pix Automático, PIX manual) — quando voltar, adicionar spec `pagamentos.md`
- Chat in-app (alternativa ao WhatsApp)
- Multi-tenant (vários grupos no mesmo app)
- Web admin
- Dark mode
- Login social (Google/Apple)
- CRDTs (se concorrência crescer com multi-admin)
- **Broadcast em tempo real do placar/cronômetro** entre celulares (uma só fonte de verdade durante o jogo)
- **Persistir times sorteados e placar final do jogo** (se a turma quiser histórico de "Time X venceu Y")
- Exportar relatório do mês (PDF)
