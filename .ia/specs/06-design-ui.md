# 06 — Design e UI

Sistema visual do app: paleta, tipografia, espaçamento e componentes base. Tudo centralizado em `ThemeData` (`lib/core/theme/`) — **nenhum widget usa cor literal**, sempre via tokens.

## Paleta de cores

5 cores em tom **quente harmonizado** (o marrom-bege puxa o branco e o cinza para o lado quente). Nomes semânticos para facilitar leitura no código.

| Token | Hex | Papel principal |
|---|---|---|
| `ink` | `#0F0F0E` | Preto carvão — texto primário, ícones |
| `leather` | `#A88C6C` | Marrom-bege (couro de bola) — primary/acento (botão "Vou!", links, CTAs) |
| `chalk` | `#FAF7F2` | Off-white quente — background principal (lembra linhas da quadra) |
| `stone` | `#5C5A56` | Cinza médio — texto secundário, bordas |
| `mist` | `#E5E1DB` | Cinza claro quente — surfaces, dividers, estado disabled |

### Variantes derivadas

Usar `Color.withOpacity` apenas pelos helpers de extensão (`ink.muted`, `leather.subtle`, etc.) — evita números mágicos espalhados:

| Helper | Equivalente |
|---|---|
| `ink.muted` | `ink.withOpacity(0.6)` — hint text, ícones inativos |
| `ink.disabled` | `ink.withOpacity(0.38)` — estado disabled |
| `leather.subtle` | `leather.withOpacity(0.12)` — background de chip selecionado, hover |
| `leather.pressed` | `leather.withOpacity(0.16)` — estado pressed |

### Cores semânticas

Para estados que precisam comunicar mais (sucesso, erro, alerta), usar tokens dedicados — não as cores principais. Conservar o tom quente:

| Token | Hex | Uso |
|---|---|---|
| `success` | `#5C7A4A` | verde oliva escuro — confirmação |
| `warning` | `#C8954E` | âmbar quente — atenção |
| `danger` | `#A24C3B` | terracota — erro, destrutivo |

## Tipografia

- **Família**: **Inter** (fallback: `-apple-system`, `Roboto`)
- Suporta bem pt-BR, neutra, ótima em telas pequenas

Escala (6 níveis):

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `display` | 32 | 700 | Headers de tela grande |
| `title` | 22 | 700 | Títulos de seção (cards, dialogs) |
| `subtitle` | 18 | 500 | Subtítulos |
| `body` | 16 | 400 | Texto corrido |
| `bodyStrong` | 16 | 500 | Texto corrido com ênfase |
| `caption` | 13 | 400 | Labels, meta, "Última atualização: ..." |

## Espaçamento

Escala de **4px**, exposta como `Spacing.xs`, `Spacing.sm`, etc.:

| Token | px |
|---|---|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `2xl` | 48 |

Padding default de tela: `Spacing.md` (16) horizontal, `Spacing.lg` (24) vertical no topo.

## Border radius

| Token | px | Uso |
|---|---|---|
| `radiusSm` | 8 | chips, inputs |
| `radiusMd` | 12 | botões, cards pequenos |
| `radiusLg` | 16 | cards grandes, bottom sheets |

## Componentes base

Lista mínima a implementar em `lib/core/widgets/`:

- **`AppButton`** — variantes: `primary` (fundo `leather`, texto `chalk`), `secondary` (borda `ink`, texto `ink`, fundo `chalk`), `ghost` (sem borda, texto `leather`), `danger` (fundo `danger`)
- **`AppCard`** — superfície `chalk` ou `mist`, borda 1px `mist`, radius `lg`
- **`PlayerTile`** — avatar circular + nome + chip de goleiro quando aplicável + chip de label (mensalista/avulso)
- **`SkillScoreBadge`** — exibe o `skill_score` do usuário logado na Home (0–100); não usado para mostrar skill de outros players
- **`SkillRatingSlider`** — slider de 0 a 100 para avaliação de habilidade; exibe apenas a nota que o usuário está dando/editando naquele momento
- **`AttendanceChip`** — chip colorido por status: `confirmed` (verde `success.subtle`), `declined` (cinza), `pending` (âmbar)
- **`StatusBanner`** — banner topo da tela mostrando "Offline" / "Sincronizando..." / "Atualizado agora"
- **`BottomSheet`** padrão — header com handle, padding `lg`, surface `chalk`

## `ThemeData` (estrutura)

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.chalk,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.leather,
          onPrimary: AppColors.chalk,
          surface: AppColors.chalk,
          onSurface: AppColors.ink,
          // ... derivar do conjunto
        ),
        textTheme: AppTextTheme.build(),
        // overrides de componentes
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.ink,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.leather,
          onPrimary: AppColors.ink,
          surface: AppColors.ink,
          onSurface: AppColors.chalk,
          // ... inversão do background principal + textos/surfaces via tokens
        ),
        textTheme: AppTextTheme.build(),
        // overrides de componentes
      );
}
```

Arquivos no diretório:
- `lib/core/theme/app_colors.dart` — só constantes hex + extensões
- `lib/core/theme/app_text_theme.dart` — escala tipográfica
- `lib/core/theme/app_spacing.dart` — escala de espaçamento
- `lib/core/theme/app_radius.dart` — radius
- `lib/core/theme/app_theme.dart` — composição final

## Regras invariáveis

1. **Nenhum widget usa cor literal**. Sempre `AppColors.leather`, nunca `Color(0xFFA88C6C)`.
2. **Nenhum widget usa padding literal**. Sempre `Spacing.md`, nunca `EdgeInsets.all(16)`.
3. **Componentes base ficam em `lib/core/widgets/`** e são reusados — não recriar `AppButton` em features.
4. **Linter**: configurar `flutter_lints` + regra custom para barrar literal de cor em arquivos fora de `lib/core/theme/`.

## Tema escuro

O app terá tema escuro. Ele não é uma paleta nova: é a inversão do background principal com os mesmos tokens.

| Light | Dark |
|---|---|
| `chalk` (bg) | `ink` |
| `ink` (text) | `chalk` |
| `leather` (primary) | `leather` (mantém) |
| `mist` (surface) | `stone` |
| `stone` (text-secondary) | `mist` |

Regras:
- `AppTheme.light()` usa `chalk` como background principal.
- `AppTheme.dark()` usa `ink` como background principal.
- Widgets continuam proibidos de usar cores literais; tema claro/escuro sempre vem de `ThemeData` e tokens.
- O tema pode seguir a preferência do sistema operacional por padrão, com opção futura de override manual.
