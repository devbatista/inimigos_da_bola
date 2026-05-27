# 05 — Autenticação e autorização

## Stack

- **`devise`** + **`devise-jwt`** no Rails para emissão/revogação de JWT
- **`pundit`** para autorização (policies por recurso)
- **`flutter_secure_storage`** no client para guardar access + refresh token criptografados (Keychain no iOS, Keystore no Android)
- **`bcrypt`** para hash de senha

## Fluxos

### Convite (admin convida jogador)

1. Admin clica "Convidar jogador" → preenche email e nome
2. Server cria `User` com `role: player`, `player_type: casual`, sem senha, status `invited`, gera token de convite (JWT curto, 7 dias). `casual` é apenas o valor inicial padrão.
3. Server retorna link `https://app.inimigosdabola.com/invite?token=<jwt>`
4. Admin compartilha o link manualmente (WhatsApp, etc.) — no MVP não enviamos email
5. Jogador abre o link no app → tela "Aceitar convite":
   - Pré-preenche nome (editável)
   - Pede senha + confirmação
   - Pede `player_type` com `casual` pré-selecionado; jogador pode trocar para `monthly`
   - Pede para informar se é goleiro
6. App envia para `POST /api/v1/users/accept_invitation`
7. Server valida token, define senha (bcrypt), ativa o user, emite access + refresh JWT

### Login

1. App: tela com email + senha
2. `POST /api/v1/auth/sign_in` → resposta com `access_token` (curto, 15 min) e `refresh_token` (longo, 30 dias)
3. App salva ambos em `flutter_secure_storage`
4. Mantém usuário logado entre cold starts (lê do storage)

### Refresh

1. Ao chamar API, interceptor adiciona `Authorization: Bearer <access_token>`
2. Se 401 com `code: token_expired`: interceptor chama `POST /api/v1/auth/refresh` com `refresh_token`
3. Recebe novo `access_token` (e às vezes rotaciona o `refresh_token`)
4. Repete a request original
5. Se refresh também falha (refresh expirado/revogado): força logout

### Logout

1. `DELETE /api/v1/auth/sign_out` → server adiciona JWT à **denylist** (`jwt_denylist` table)
2. App apaga tokens do `flutter_secure_storage`
3. Volta para tela de login

### Recuperação de senha

- `POST /api/v1/auth/password` com email → server envia email com token
- Tela no app para colar token + nova senha → `PUT /api/v1/auth/password`
- **Requer rede** (sem fluxo offline)

## Roles

| Role | Pode |
|---|---|
| `admin` | Tudo: criar/editar sessões semanais, convidar jogadores, sortear times, lançar stats, mudar label de qualquer jogador |
| `player` | Confirmar/cancelar a própria presença, editar próprio perfil, ver listas e ranking |

- O **primeiro user criado** no banco é o `admin` (organizador da turma). Configurado via seeds.
- No MVP, **não há transferência ou múltiplos admins**. Adicionar quando o grupo crescer.

## Autorização (Pundit)

Cada recurso tem uma `Policy`. Exemplos:

```ruby
# app/policies/weekly_session_policy.rb
class WeeklySessionPolicy < ApplicationPolicy
  def create?  = user.admin?
  def update?  = user.admin?
  def show?    = true   # qualquer logado vê
end

# app/policies/attendance_policy.rb
class AttendancePolicy < ApplicationPolicy
  def create? = user.admin? || record.user_id == user.id
  def update? = user.admin? || record.user_id == user.id
  def destroy? = user.admin? || record.user_id == user.id
end
```

Controllers chamam `authorize @weekly_session` no início das ações. Em falha, retornam `403`.

## Sessão offline

- JWT (access + refresh) em `flutter_secure_storage`
- Ao abrir o app sem rede:
  - Lê tokens do storage
  - Decodifica access token localmente; se `exp` não passou, considera válido para abrir UI
  - Se passou, ainda abre UI (modo offline) mas marca o estado como "precisa refresh ao reconectar"
- Refresh só acontece quando há rede
- Logout offline: apaga tokens locais imediatamente; quando reconectar, manda o denylist post (best-effort)

## Espelho de roles no client

- Após login, app salva o `role` retornado em campo no Drift (`users.role`)
- UI esconde botões de admin para `player` (gating local)
- Server **continua** sendo autoridade — qualquer ação ainda passa por Pundit
- Necessário porque, offline, o client precisa decidir o que mostrar sem chamar a API

## Endpoints

| Método | Path | Função |
|---|---|---|
| POST | `/api/v1/auth/sign_in` | login |
| DELETE | `/api/v1/auth/sign_out` | logout |
| POST | `/api/v1/auth/refresh` | refresh token |
| POST | `/api/v1/auth/password` | solicita reset |
| PUT | `/api/v1/auth/password` | aplica novo password com token |
| POST | `/api/v1/users/invitations` | admin convida (gera token) |
| POST | `/api/v1/users/accept_invitation` | jogador aceita convite |

## Segurança — checklist

- Senha mínima 8 caracteres, sem regras maximalistas (OWASP)
- Rate limiting nos endpoints de auth (`rack-attack`)
- JWT com `iss`, `aud`, `exp`, `jti` para denylist
- Refresh token rotacionado a cada refresh bem-sucedido
- HTTPS obrigatório em produção
- `flutter_secure_storage` com `IOSOptions(accessibility: first_unlock_this_device)` (não migra em backups) e `AndroidOptions(encryptedSharedPreferences: true)`
