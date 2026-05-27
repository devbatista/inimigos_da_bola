# 07 — Convenções de código

## Geral (Flutter + Rails)

- **Código em inglês**: identificadores, nomes de arquivos, branches, commits, comentários
- **UI em pt-BR**: strings visíveis ao usuário, mensagens de erro, labels — sempre via `intl` (`AppLocalizations`)
- **Timestamps**: UTC no banco e na API; conversão para `America/Sao_Paulo` só na camada de view
- **IDs**: UUID v7 em todas as entidades sincronizáveis
- **Datas em texto**: formato `dd/MM/yyyy`, horário `HH:mm` (24h)
- **Idioma de commits**: inglês, Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`)
- **Branches**: `feat/<short-slug>`, `fix/<short-slug>`, `chore/<short-slug>`
- **PRs**: pequenos (idealmente < 400 linhas mudadas); descrição explica o "porquê", não o "o quê"

## Flutter

### Estrutura de pastas

```
lib/
├── core/
│   ├── db/              # Drift database, DAOs, migrations
│   ├── sync/            # Sync engine
│   ├── theme/           # Tokens de design (06-design-ui.md)
│   ├── widgets/         # Componentes base reutilizáveis
│   ├── api/             # http client + interceptors
│   ├── auth/            # session manager, token storage
│   ├── time/            # clock injetável
│   └── utils/           # helpers genéricos (rare; preferir features/)
├── features/
│   └── <feature>/
│       ├── data/        # repositories
│       ├── domain/      # models (freezed), value objects
│       └── presentation/
│           ├── screens/
│           ├── widgets/
│           └── providers/   # riverpod providers (state)
├── l10n/                # arb files (pt.arb principal)
└── main.dart
```

### Padrões obrigatórios

- **Repository é o único caminho de leitura/escrita.** Telas e providers nunca chamam Dio direto, nunca chamam DAO direto.
- **Reads via Stream** (`Stream<List<T>>` do Drift). Telas usam `ref.watch(...Provider)` que envolve esse stream.
- **Writes via Future**, com transação atômica (DB local + sync_queue).
- **Exceção de presença**: confirmar/cancelar presença chama o backend imediatamente via repository e só atualiza o Drift após resposta; não entra em `sync_queue`.
- **Riverpod**: usar `riverpod_generator` para todos os providers. Não declarar `Provider`/`StateProvider` manualmente.
- **Models de domínio**: `freezed` para imutabilidade e cópia.
- **Sem cor literal** fora de `lib/core/theme/` (regra do design system, ver [06-design-ui.md](06-design-ui.md)).
- **Sem padding/spacing literal** fora de `lib/core/theme/`. Sempre via `Spacing.md`, etc.

### Naming

- Classes/Enums: `PascalCase`
- Arquivos: `snake_case.dart`
- Constantes top-level: `lowerCamelCase` (Dart convention — não `UPPER_CASE`)
- Providers: sufixo `Provider` (`currentWeeklySessionProvider`)
- Notifiers: sufixo `Notifier` (`AttendanceNotifier`)

### Testes

- `flutter_test` + `riverpod` test helpers
- Unit tests para domain (algoritmos puros — sorteio, scoring) e data (repositories com Drift in-memory)
- Widget tests para screens críticas (home, sorteio)
- Integration tests (golden path) para confirmação de presença end-to-end
- Mock de network com `mocktail`; nunca mockar Drift (usar SQLite in-memory)

### Lint

- `flutter_lints` (pacote oficial)
- Regras custom em `analysis_options.yaml`:
  - `prefer_const_constructors`
  - `avoid_print`
  - `prefer_single_quotes`
  - Custom lint (escrever um, se faltar) que barra `Color(0x...)` fora de `lib/core/theme/`

## Rails

### Padrões

- **API versionada**: `/api/v1/...` em todos os endpoints
- **Controllers magros**: só parse + chamada de service + render. Sem regra de negócio.
- **Services**: classes em `app/services/`, organizadas por feature (`Attendance::Confirm`, `Teams::Draw`, etc.). Cada service tem método `.call` e retorna `Success.new(data)` ou `Failure.new(code, message)` (usar `dry-monads` ou objeto próprio).
- **Models**: ActiveRecord com validações estruturais, escopos, e callbacks **apenas** para `updated_at` / `version`. Sem regra de negócio.
- **Serializers**: Blueprinter (ou jsonapi-serializer) em `app/serializers/`. Nunca usar `to_json` ad-hoc.
- **Jobs**: Sidekiq em `app/jobs/<feature>/<verb>_job.rb`.
- **Policies**: Pundit em `app/policies/<resource>_policy.rb`.

### Envelope de erro

Toda resposta de erro segue:

```json
{
  "error": {
    "code": "ATTENDANCE_LIMIT_REACHED",
    "message": "O racha já está com vagas preenchidas; você entrou na lista de espera."
  }
}
```

Códigos em `SCREAMING_SNAKE_CASE`, listados em `config/error_codes.rb` (uma única fonte de verdade).

### Naming

- Arquivos/módulos: `snake_case`
- Classes: `PascalCase`
- Métodos/variáveis: `snake_case`
- Constantes: `SCREAMING_SNAKE_CASE`
- Endpoints REST padrão (`index`, `show`, `create`, `update`, `destroy`). Ações custom em endpoints membros (`POST /weekly_sessions/:id/stats` para lançar gols em lote).

### Testes

- **RSpec** + **FactoryBot** + **VCR** (para chamadas externas, quando voltar a ter)
- Specs por tipo: `spec/models/`, `spec/services/`, `spec/requests/`, `spec/policies/`
- Cobertura mínima ambicionada: **services 90%+**, **requests 80%+**
- Sem mock de DB; usar `database_cleaner-active_record` com transactional fixtures

### Lint

- **Rubocop** com `rubocop-rails`, `rubocop-rspec`
- Configuração em `.rubocop.yml`; reúsa `rubocop-shopify` ou estilo equivalente
- CI bloqueia merge se Rubocop falhar

### Migrations

- Reversíveis sempre que possível
- Adicionar índices na mesma migration que cria coluna usada em query
- Sempre setar `default` em colunas `NOT NULL` adicionadas em tabelas com dados existentes
- Soft-delete via `deleted_at` (já documentado em [02-modelo-dados.md](02-modelo-dados.md)) — nada de `DELETE` físico em entidades sincronizáveis

## Git e CI

- Branch principal: `main`
- PRs com revisão obrigatória (mínimo 1 aprovação, no MVP é só o organizador → auto-revisa via CI)
- CI roda em todo PR:
  - **Flutter**: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`
  - **Rails**: `bundle exec rspec`, `bundle exec rubocop`, `bundle exec brakeman`
- Deploy em `main` (continuous deploy para staging; produção via tag)
