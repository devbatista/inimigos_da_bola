# 04 — Features

Quatro blocos no MVP: **Jogadores + Presença**, **Sorteio de times** (temporário), **Cronômetro + Placar** (temporários) e **Estatísticas + Notificações**. Cada um descreve telas principais, regras de domínio, endpoints e comportamento offline.

> **Convenção sobre "temporário"**: features marcadas como temporárias (sorteio, cronômetro, placar) vivem apenas em **estado in-memory** (Riverpod) no app de **cada usuário** que abrir a tela. Não passam por Drift nem pela API. Ao sair da tela, fechar o app ou matar o processo, os dados se perdem — é intencional. Não há "estado oficial compartilhado": cada celular tem o seu, e dois usuários podem ter estados diferentes ao mesmo tempo (parte aceita do design — são ferramentas, não fonte de verdade). Quando alguém precisa "salvar" o resultado do jogo, o admin lança gols/assistências por jogador na tela de stats (F4), e **só esses dados persistem**.

---

## F1 — Jogadores + Confirmação de Presença

### Telas

**Home (tela principal do app)**
- Card destacado "Racha de segunda — DD/MM" no topo
  - Botão grande "Vou!" / "Não vou" (toggle do próprio jogador)
  - Contador `X de Y confirmados` (X = confirmados, Y = `max_players`)
  - Local (lido da config do clube) e horário
- Listas separadas:
  - **Confirmados** (avatar + nome + posição + label mensalista/avulso)
  - **Lista de espera** (numerada, "1º na fila", "2º na fila", ...)
  - **Não vão** (recolhível)
  - **Pendentes** (recolhível, jogadores convidados que ainda não decidiram)
- Selo "Última atualização: HH:MM" indicando idade do cache

**Lista de jogadores (admin)**
- Tabela com todos os cadastrados: nome, label (mensalista/avulso), posição, nível
- Filtros por label e por posição
- Ações: editar, mudar label, mudar nível, soft-delete
- Botão "Convidar novo jogador" → gera link mágico (ver [05-autenticacao.md](05-autenticacao.md))

**Perfil do jogador**
- Próprio perfil ou de outro jogador (visualização)
- Dados pessoais, posição, nível
- Histórico: presenças no mês, gols na temporada, ranking de artilharia

### Regras de domínio

- O `Match` de cada segunda é criado automaticamente pelo job `Matches::CreateWeeklyJob` (cron Sidekiq) toda segunda às 8h
  - `scheduled_at` = segunda atual com horário do clube vindo de `config/club.yml`
  - `max_players` = valor do clube (default 14, configurável)
  - `status` = `scheduled`
- Jogadores confirmam até a hora do `scheduled_at`; depois disso, presença vira read-only
- Quando os confirmados atingem `max_players`, novas confirmações entram em **lista de espera** (`waitlist_position` 1, 2, 3, ...)
- Quando alguém com `status: confirmed` cancela, o primeiro da lista de espera é **promovido** para `confirmed` (e recebe push)
- Cancelar uma confirmação muda `status` para `declined` e libera vaga
- Cadastro de jogador novo: admin clica em "Convidar" → server gera token → admin compartilha link → ao abrir, jogador completa nome/posição → entra como `role: player`, `player_type: casual` por default

### Endpoints

- `GET /api/v1/club` — config do clube (local, horário, dia da semana, max_players)
- `GET /api/v1/matches/current` — racha da semana corrente (cria se não existir)
- `GET /api/v1/matches/:id` — detalhes
- `POST /api/v1/matches/:id/attendances` — confirmar/recusar (body: `{ status: confirmed|declined }`)
- `GET /api/v1/matches/:id/attendances` — lista (também vem via pull de sync)
- `POST /api/v1/users/invitations` — admin gera convite
- `POST /api/v1/users/accept_invitation` — jogador aceita

### Comportamento offline

- Confirmar/cancelar presença → mutação local + sync_queue; UI atualiza imediatamente
- Lista de confirmados → renderizada do cache local com selo "Última atualização"
- Cadastrar novo jogador (admin) → UUID v7 gerado local; sincroniza depois
- Convite por link mágico → requer rede (server precisa gerar token assinado)
- Promoção da lista de espera quando alguém cancela offline → resolvida no server quando reconectar; UI local pode mostrar previsão otimista (primeiro da lista vira "provavelmente confirmado")

---

## F2 — Sorteio de times (temporário)

> **Aberto a qualquer usuário** (admin ou player). É uma ferramenta visual: cada celular tem o seu resultado, **nada persiste**.

### Telas

**Sorteio**
- Disponível na seção "Ferramentas da quadra" (mesmo lugar do cronômetro e placar)
- Permite escolher manualmente quem entra no sorteio (default: os confirmados do racha atual; pode adicionar/remover)
- Configurável: número de times (default 2), tamanho do time
- Botão "Sortear" → roda o algoritmo, mostra o resultado em cards lado a lado
- Cada card: nome do time (default `Time A`, `Time B`; editável in-place) + lista de jogadores com posição
- Ações: "Refazer sorteio" (nova semente), "Trocar manualmente" (drag-and-drop de jogador entre cards), "Limpar"
- **Sem botão de salvar.** O resultado fica enquanto a tela estiver viva.

### Algoritmo de sorteio

**Snake draft por nível**, totalmente client-side:
1. Pega a lista de participantes (default: confirmados; admin/player pode editar manualmente antes do sorteio)
2. Ordena por `skill_level` desc, com desempate aleatório dentro de cada nível
3. Distribui em N times em padrão "serpente": A, B, B, A, A, B, B, A, ...
4. Ajuste opcional: tenta colocar 1 goleiro por time se houver `preferred_position: goalkeeper`
5. Seed pseudoaleatória exposta para reproduzibilidade durante a sessão (não persiste)

Arquivo: `lib/features/teams/domain/draw_algorithm.dart` (função pura, testável).

### Estado

- `TeamsDrawState` em Riverpod (`AutoDispose` — descarta quando a tela some)
- Não há endpoint, não há tabela no Drift, não há sync

### Comportamento offline

- 100% offline (algoritmo no client, sem rede)
- Dois usuários podem rodar o sorteio ao mesmo tempo e ter resultados diferentes — esperado

---

## F3 — Cronômetro + Placar (temporários)

> **Aberto a qualquer usuário**. Ferramentas de quadra; cada celular tem o seu estado. **Nada persiste.**

### Telas

**Tela única "Modo Jogo"** (na seção "Ferramentas da quadra")
- Layout fullscreen orientado à legibilidade no campo de visão de longe:
  - **Placar grande no topo**: `Time A` vs `Time B` — números em fonte enorme (`display` ou maior), com botões `+` e `−` por time
  - **Nomes dos times editáveis** (tap → edita; default `Time A`, `Time B`)
  - **Cronômetro no centro**: `MM:SS` em fonte gigante
    - Modo configurável: **progressivo** (sobe desde zero) ou **regressivo** (default 20:00, configurável)
    - Botões: `Iniciar`, `Pausar`, `Resetar`
    - Indicador opcional de período (`1º tempo`, `Intervalo`, `2º tempo`) — chip secundário tocável
  - Botão "Fechar" (volta para a tela anterior; estado se perde)
- Wakelock ativo enquanto a tela estiver aberta (não deixa o celular dormir)

### Regras

- Estado em Riverpod `AutoDispose`
- Cronômetro usa `Ticker` (60Hz) ou timer de 1s, atualizando o display
- Se o app for para background:
  - Cronômetro **continua contando matematicamente** (guarda `started_at_monotonic` em memória)
  - Ao voltar, recalcula a partir do tempo real decorrido
  - Se o app for **morto**, o estado se perde — comportamento aceito
- Placar é só dois inteiros (`scoreA`, `scoreB`) com `+`/`−` (não desce abaixo de 0)
- **Sem broadcast entre dispositivos no MVP** — se a turma quiser uma única fonte de verdade, alguém deixa o seu celular como o "placar oficial"

### Estado

- `GameModeState { scoreA, scoreB, teamAName, teamBName, timerMode, elapsed, isRunning, period }` em Riverpod `AutoDispose`
- Sem persistência, sem sync

### Comportamento offline

- 100% offline. Não precisa de rede para nada.

---

## F4 — Estatísticas + Notificações

### Telas

**Lançamento de stats (admin, pós-jogo)**
- Lista os jogadores que estavam no match
- Para cada um: inputs para `goals` e `assists`
- Botão "Salvar e finalizar partida" → marca `match.status = finished`

**Ranking de artilheiros**
- Top N jogadores por gols na temporada (configurável: mês corrente, ano)
- Coluna secundária: assistências
- Tabela ordenável

**Histórico do jogador (no perfil)**
- Lista de matches em que participou
- Para cada um: gols, assistências, status do time (apenas se quisermos mostrar resultado, fora do MVP)

### Push Notifications (FCM)

- **Convite de presença** (segunda de manhã, após `CreateWeeklyJob` rodar): "O racha de hoje está aberto. Você vai?"
- **Lembrete de jogo** (1h antes do `scheduled_at`): "Em 1h tem racha. Já confirmou?"
- **Promovido da lista de espera**: "Abriu vaga! Você está confirmado para hoje."
- **Sync silencioso** (data message, não exibe notificação): trigger para o app puxar atualizações

### Regras

- Apenas `admin` registra stats
- Stats podem ser editados até 24h após o jogo (depois disso, locked)
- FCM tokens são armazenados em `user.fcm_token` (coluna a adicionar quando push for implementado no Sprint 6)

### Endpoints

- `POST /api/v1/matches/:id/stats` — batch de stats por jogador
- `GET /api/v1/stats/leaderboard?period=month|year` — ranking
- `POST /api/v1/users/me/fcm_token` — registra/atualiza token do device

### Comportamento offline

- Lançamento de stats funciona 100% offline (admin no celular sem rede pós-jogo)
- Ranking lê do cache local; reflete o que sincronizou
- Push notifications precisam de rede (FCM)
