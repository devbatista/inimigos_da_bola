# Checklist de Desenvolvimento Mobile

Checklist prático para implementar o app Flutter do Inimigos da Bola.

## Regras-base

- UI em pt-BR com acentuação correta.
- Identificadores, arquivos e branches em inglês.
- Comentários e commits em português.
- Commits seguem Conventional Commits.
- Sem cores literais em widgets; usar tokens do design system.
- Sem padding/spacing literal fora de `lib/core/theme`.
- UI lê do Drift/local por padrão.
- Confirmação/cancelamento de presença é exceção: chamada online imediata.
- Sorteio, cronômetro e placar vivem só em memória.

## Sprint 0 — Base do projeto

- [ ] Revisar `pubspec.yaml` e adicionar dependências mobile:
  - [x] `flutter_riverpod`
  - [x] `riverpod_annotation`
  - [ ] `riverpod_generator` — adiado até usarmos providers gerados; conflita com `drift_dev`/`analyzer` neste momento
  - [x] `build_runner`
  - [x] `freezed`
  - [x] `freezed_annotation`
  - [x] `json_annotation`
  - [x] `json_serializable`
  - [x] `drift`
  - [x] `drift_flutter` ou `sqlite3_flutter_libs`
  - [x] `path_provider`
  - [x] `dio`
  - [x] `flutter_secure_storage`
  - [x] `local_auth`
  - [x] `intl`
  - [x] `connectivity_plus`
  - [x] `firebase_core`
  - [x] `firebase_messaging`
  - [x] `wakelock_plus`
  - [x] `mocktail`
- [x] Criar estrutura:
  - [x] `lib/core/api`
  - [x] `lib/core/auth`
  - [x] `lib/core/db`
  - [x] `lib/core/sync`
  - [x] `lib/core/theme`
  - [x] `lib/core/time`
  - [x] `lib/core/widgets`
  - [x] `lib/features/players`
  - [x] `lib/features/attendance`
  - [x] `lib/features/teams`
  - [x] `lib/features/game_mode`
  - [x] `lib/features/stats`
- [x] Configurar `intl` e arquivos `.arb`.
- [x] Configurar `analysis_options.yaml` com regras do projeto.
- [x] Configurar codegen com `build_runner`.
- [x] Criar app shell com rotas iniciais.
- [x] Criar tela inicial temporária com nome do app.
- [x] Garantir que `flutter test` roda.

## Design system

- [x] Criar `lib/core/theme/app_colors.dart`.
- [x] Criar tokens:
  - [x] `ink`
  - [x] `leather`
  - [x] `chalk`
  - [x] `stone`
  - [x] `mist`
  - [x] `success`
  - [x] `warning`
  - [x] `danger`
- [x] Criar helpers de opacidade (`muted`, `disabled`, `subtle`, `pressed`).
- [x] Criar `app_text_theme.dart`.
- [x] Criar `app_spacing.dart`.
- [x] Criar `app_radius.dart`.
- [x] Criar `AppTheme.light()`.
- [x] Criar `AppTheme.dark()` com inversão do background principal.
- [x] Seguir preferência do sistema para claro/escuro.
- [x] Criar componentes base:
  - [x] `AppButton`
  - [x] `AppCard`
  - [x] `PlayerTile`
  - [x] `SkillScoreBadge`
  - [x] `SkillRatingSlider`
  - [x] `AttendanceChip`
  - [x] `StatusBanner`
  - [x] `AppBottomSheet`

## Navegação e menu

- [x] Criar shell autenticado com menu inferior fixo.
- [x] Criar itens principais no menu inferior:
  - [x] Início
  - [x] Sorteio
  - [x] Modo Jogo
  - [x] Stats
- [x] Criar item "Mais" para ações secundárias:
  - [x] Confirmações avulsas
  - [x] Jogadores
  - [x] Configurações
- [x] Criar placeholders para telas ainda não implementadas.
- [x] Adicionar ação de logout no menu.

## Banco local Drift

- [x] Criar database Drift.
- [x] Criar tabela local `users`.
- [x] Criar tabela local `weekly_sessions`.
- [x] Criar tabela local `attendances`.
- [x] Criar tabela local `skill_ratings` apenas para notas dadas pelo usuário logado, se necessário.
- [x] Criar tabela local `session_stats`.
- [x] Criar tabela `sync_queue`.
- [x] Criar tabela `sync_state`.
- [x] Criar DAOs por feature.
- [x] Criar migrations versionadas.
- [x] Garantir que campos Devise sensíveis não existem localmente.

## API client

- [x] Criar `Dio` client central.
- [x] Configurar `API_BASE_URL`.
  - [x] Default local ajustado para `http://localhost:4500/api/v1`.
- [x] Adicionar interceptor de auth.
- [x] Adicionar refresh token automático.
- [x] Padronizar parsing de erros `{ error: { code, message } }`.
- [x] Criar cliente para:
  - [x] Auth
  - [x] Users
  - [x] Weekly sessions
  - [x] Attendances
  - [x] Guest attendances
  - [x] Skill ratings
  - [x] Stats
  - [x] Sync
  - [x] FCM token

## Autenticação

- [x] Tela de login com email + senha para primeiro acesso/login manual.
- [x] Login usa backend real via `POST /api/v1/auth/sign_in`.
- [x] Inputs de email/senha aceitam foco e digitação no simulador.
- [ ] Fluxo de aceite de convite por deep link.
- [ ] Tela de convite:
  - [ ] Nome editável
  - [ ] Senha + confirmação
  - [ ] `player_type` com `casual` pré-selecionado
  - [ ] Marcação `goalkeeper`
- [x] Salvar `access_token` e `refresh_token` em `flutter_secure_storage`.
- [x] Salvar usuário logado no Drift ao carregar dados da Home.
- [ ] Implementar desbloqueio local:
  - [ ] Biometria com `local_auth`
  - [ ] Senha como fallback
- [ ] Implementar logout.
- [ ] Implementar recuperação de senha.
- [ ] Abrir app offline se houver sessão/cache válidos.

## Home

- [x] Criar tela principal.
- [x] Exibir card do racha semanal.
- [x] Exibir local e horário na UI inicial.
- [ ] Integrar local e horário com `GET /api/v1/club`.
- [x] Exibir botão "Vou!" / "Não vou".
- [x] Exibir contador público `X de Y confirmados`.
- [x] Exibir `Meu skill` com `SkillScoreBadge`.
- [x] Exibir listas:
  - [x] Confirmados
  - [x] Lista de espera
  - [x] Não vão
  - [x] Pendentes
- [x] Seções "Não vão" e "Pendentes" recolhíveis.
- [x] Exibir selo "Última atualização: HH:MM".
- [x] Garantir que lista e contador vêm do Drift/cache.
- [x] Carregar sessão atual, usuários e presenças a partir do backend/cache.

## Presença

- [x] Implementar `AttendanceRepository`.
- [x] Confirmar/cancelar presença com chamada online imediata.
- [x] Não usar `sync_queue` para presença.
- [x] Não fazer update otimista de `attendances`.
- [x] Sem rede: mostrar erro e manter estado local anterior.
- [x] Após sucesso: gravar resposta no Drift.
- [x] Atualizar contador/listas após resposta.
- [x] Tratar lista de espera retornada pelo backend.

## Presenças avulsas do admin

- [x] Criar tela admin "Confirmações avulsas".
- [x] Criar `GuestAttendanceRepository`.
- [x] Botão "Adicionar avulso".
- [x] Input de nome.
- [x] Chamar `POST /weekly_sessions/:id/guest_attendances`.
- [x] Permitir remover/cancelar presença avulsa.
- [x] Chamar `DELETE /weekly_sessions/:id/guest_attendances/:attendance_id`.
- [x] Não usar `sync_queue`.
- [x] Sem rede: mostrar erro e manter estado local anterior.
- [x] Garantir que presença avulsa atualiza contador e listas após resposta.

## Lista de jogadores

- [ ] Tela admin com jogadores cadastrados.
- [ ] Mostrar nome, label mensalista/avulso e goleiro.
- [ ] Filtros por label e goleiro.
- [ ] Ações:
  - [ ] Editar dados permitidos
  - [ ] Mudar label
  - [ ] Soft-delete
- [ ] Botão "Convidar novo jogador".
- [ ] Gerar convite via backend.

## Avaliação de habilidade

- [ ] Criar tela/fluxo para avaliar outros players.
- [ ] Usar `SkillRatingSlider` de 0 a 100.
- [ ] Não permitir autoavaliação.
- [ ] Bloquear reavaliação do mesmo player antes de 1 mês.
- [ ] Enviar `POST /api/v1/skill_ratings`.
- [ ] Não mostrar notas individuais recebidas.
- [ ] Não mostrar notas dadas por outros.
- [ ] Mostrar apenas o próprio `skill_score` na Home.

## Sorteio de times

- [ ] Criar tela "Sorteio".
- [ ] Carregar automaticamente confirmados do racha atual.
- [ ] Incluir presenças avulsas adicionadas pelo admin.
- [ ] Permitir adicionar avulso temporário local.
- [ ] Avulso temporário vive só em `TeamsDrawState`.
- [ ] Permitir remover participante apenas localmente.
- [ ] Configurar número de times.
- [ ] Configurar tamanho do time.
- [ ] Implementar algoritmo snake draft.
- [ ] Ordenar por `skill_score`.
- [ ] Para presenças avulsas/temporárias, usar skill mediano dos cadastrados confirmados.
- [ ] Se não houver cadastrados confirmados, usar skill 50.
- [ ] Tentar distribuir goleiros (`goalkeeper: true`).
- [ ] Permitir refazer sorteio.
- [ ] Permitir troca manual por drag-and-drop.
- [ ] Permitir editar nomes dos times.
- [ ] Não salvar resultado.
- [ ] Não criar endpoint.
- [ ] Não criar tabela Drift.
- [ ] Testar algoritmo.

## Cronômetro + placar

- [ ] Criar tela "Modo Jogo".
- [ ] Placar grande `Time A` vs `Time B`.
- [ ] Botões `+` e `-` por time.
- [ ] Nomes dos times editáveis.
- [ ] Cronômetro central `MM:SS`.
- [ ] Modo progressivo.
- [ ] Modo regressivo com default `08:00`.
- [ ] Botões `Iniciar`, `Pausar`, `Resetar`.
- [ ] Destacar fim por 8 minutos ou 2 gols.
- [ ] Usar `wakelock_plus` enquanto tela estiver aberta.
- [ ] Continuar contando matematicamente ao voltar do background.
- [ ] Estado em Riverpod `AutoDispose`.
- [ ] Sem persistência.
- [ ] Sem sync.

## Estatísticas

- [ ] Criar tela admin "Lançar stats".
- [ ] Listar jogadores cadastrados confirmados na sessão semanal.
- [ ] Inputs para gols e assistências.
- [ ] Salvar batch em `POST /weekly_sessions/:id/stats`.
- [ ] Permitir funcionamento offline-first via `sync_queue`.
- [ ] Criar tela de ranking.
- [ ] Criar histórico no perfil.
- [ ] Ranking lê do cache local.

## Notificações FCM

- [ ] Configurar Firebase.
- [ ] Configurar `firebase_messaging`.
- [ ] Pedir permissão de notificação.
- [ ] Registrar token via `POST /api/v1/users/me/fcm_token`.
- [ ] Implementar handler de background.
- [ ] Data message silenciosa dispara sync.
- [ ] Exibir notificações para:
  - [ ] Racha aberto
  - [ ] Lembrete de jogo
  - [ ] Promoção da lista de espera
  - [ ] Avisos de admin

## Sync engine

- [x] Implementar pull `GET /api/v1/sync`.
- [ ] Implementar push `POST /api/v1/sync/{entity}`.
- [ ] Usar `sync_queue` para fluxos offline-first.
- [x] Não usar `sync_queue` para presença.
- [ ] Implementar idempotency key.
- [ ] Implementar backoff exponencial.
- [ ] Marcar mutação como suspended após 10 falhas.
- [ ] Implementar tela escondida "Status de sincronização".
- [ ] Triggers:
  - [ ] Cold start
  - [ ] Reconexão de rede
  - [ ] Background periódico
  - [ ] Push silencioso
  - [ ] Pull-to-refresh

## Testes

- [ ] Unit tests do algoritmo de sorteio.
- [ ] Unit tests do cronômetro.
- [ ] Tests de repositories com Drift in-memory.
- [x] Widget tests da Home.
- [ ] Widget tests do Sorteio.
- [x] Widget tests do Login.
- [ ] Widget tests do Convite.
- [ ] Integration test de confirmação de presença online.
- [ ] Integration test de stats offline-first.
- [x] Garantir análise estática (`dart analyze`).
- [x] Garantir `flutter test`.
- [x] Garantir `dart format`.

## Critérios de pronto

- [x] UI não tem cor literal.
- [x] UI não tem texto sem acentuação.
- [x] Strings visíveis estão em pt-BR.
- [ ] Fluxos online obrigatórios falham claramente sem rede.
- [ ] Fluxos offline-first funcionam sem rede.
- [x] Drift é a fonte de leitura da UI na Home.
- [x] Nenhum widget chama Dio direto.
- [x] Nenhum widget chama DAO direto.
- [x] Tests passam antes de merge na `main`.
