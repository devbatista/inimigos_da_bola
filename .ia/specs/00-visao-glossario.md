# 00 — Visão e Glossário

## Visão de produto

Aplicativo mobile para que o organizador (admin) e os jogadores de um **racha semanal** (futsal de segunda-feira) administrem juntos: quem vai jogar, como ficam os times na quadra e qual o histórico de gols e presença. Substitui as planilhas, áudios no WhatsApp e a anotação em papel.

O usuário-alvo do MVP é **a turma do organizador** — não é um SaaS multi-grupo. A modelagem é single-tenant: o app inteiro assume um único racha recorrente.

> **Pagamentos / cobrança de mensalidade ficam fora do MVP** e devem voltar em uma sprint dedicada depois.

## Personas

### Admin (organizador)
- Configura as vagas (`max_players`) e o limite de horário para confirmar
- Cadastra e convida jogadores
- Lança gols/assistências depois do jogo

> **Data/dia recorrente, horário e local da quadra são fixos e não editáveis pela UI**. Esses valores ficam em variáveis de ambiente do backend (`RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION`) — o admin não precisa preencher nada por semana. Um job cria automaticamente a sessão semanal do racha com base nesses valores.

### Player (jogador)
- Confirma presença para a segunda específica
- Vê quem mais já confirmou
- Acompanha seu histórico de gols e presença

### Ambos (ferramentas de quadra)
- Usam **sorteio de times**, **cronômetro** e **placar** durante o jogo. Esses recursos ficam disponíveis para todos os usuários logados (admin ou player); cada celular tem o seu estado próprio, em memória, sem persistir.

## Escopo do MVP

### Dentro
- Cadastro de jogadores com marcação de goleiro (`goalkeeper: true/false`) e **label "mensalista" ou "avulso"** (organização apenas; sem fluxo de pagamento associado no MVP)
- Avaliação de habilidade: todos os players avaliam os demais com nota de 0 a 100; o sistema calcula a média e cada usuário vê apenas o próprio `skill_score` na tela principal
- Confirmação de presença para o racha da semana corrente, com lista visível dos confirmados
- Lista de espera quando passa do limite de vagas
- **Sorteio de times** (snake draft por média interna de habilidade) — ferramenta **temporária na quadra**, resultado fica em memória no dispositivo do admin, **não persiste em banco**
- **Cronômetro + placar** durante as partidas curtas — também ferramentas temporárias em memória, **não persistem em banco**
- Registro agregado de gols e assistências por sessão semanal do racha (esses sim persistem, agregados ao perfil/ranking)
- Ranking de artilheiros e histórico de presença
- Notificações push (lembrete de confirmação, lembrete de jogo)
- **Funcionamento offline-first** em todas as operações de leitura e na maioria das de escrita

### Fora do MVP
- **Pagamentos / assinatura recorrente / controle financeiro** (volta em sprint dedicada depois)
- Multi-tenant (vários grupos no mesmo app)
- Chat in-app
- Web admin (tudo é mobile)
- Dark mode
- Login social (Google/Apple)
- CRDTs para resolução fina de conflitos

## Glossário do domínio

| Termo | Significado |
|---|---|
| **Racha** | O encontro semanal da turma, normalmente na segunda-feira. No código em inglês = `WeeklySession`. |
| **Partida curta** | Jogo de quadra dentro do racha, com duração de 8 minutos ou até 2 gols. Não tem tabela própria, não é sincronizada e não é persistida no MVP. |
| **Mensalista** | Jogador com `player_type = monthly`. No MVP é só uma label organizacional (sem cobrança); quando pagamento voltar, será o jogador com assinatura ativa. |
| **Avulso** | Jogador com `player_type = casual`. No MVP é só uma label; quando pagamento voltar, será quem paga por partida. |
| **Média de habilidade** | Nota de 0 a 100 calculada a partir das avaliações que os players fazem dos demais. Cada usuário vê apenas o próprio `skill_score`; notas individuais e médias de outros players não são exibidas. |
| **Presença** | Estado do jogador para um racha: `confirmed`, `declined`, `pending`. |
| **Lista de espera** | Confirmações além de `max_players`; primeiras na fila quando alguém cancela. |
| **Sorteio** | Algoritmo de balanceamento que distribui os confirmados em times. Resultado é volátil: vale apenas para uma rodada/partida curta e vive só no app durante a sessão. |
| **Cronômetro** | Contador de tempo de jogo (in-app, em memória), com Iniciar/Pausar/Resetar. Não persiste. |
| **Placar** | Contador de gols por time (in-app, em memória), com +/- por time. Não persiste; gols individuais podem ser registrados separadamente em `session_stats` no fim do racha. |
| **Tombstone** | Marcador de deleção (`deleted_at`) propagado pela sincronização. |

## Princípios de produto

- **Caber no bolso do organizador na quadra.** O admin precisa rodar sorteio e lançar gols com luz ruim e às vezes sem rede. Por isso offline-first.
- **Convite, não cadastro aberto.** Jogadores entram por link mágico mandado pelo admin — não há signup público.
