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

> **Local da quadra e dia da semana são fixos** (toda segunda, mesmo lugar). Esses valores ficam em config do servidor — o admin não precisa preencher nada por semana. Um job cria automaticamente o `Match` da semana corrente toda segunda de manhã.

### Player (jogador)
- Confirma presença para a segunda específica
- Vê quem mais já confirmou
- Acompanha seu histórico de gols e presença

### Ambos (ferramentas de quadra)
- Usam **sorteio de times**, **cronômetro** e **placar** durante o jogo. Esses recursos ficam disponíveis para todos os usuários logados (admin ou player); cada celular tem o seu estado próprio, em memória, sem persistir.

## Escopo do MVP

### Dentro
- Cadastro de jogadores, com posição preferida, nível de habilidade e **label "mensalista" ou "avulso"** (organização apenas; sem fluxo de pagamento associado no MVP)
- Confirmação de presença para o racha da semana corrente, com lista visível dos confirmados
- Lista de espera quando passa do limite de vagas
- **Sorteio de times** (snake draft por nível) — ferramenta **temporária na quadra**, resultado fica em memória no dispositivo do admin, **não persiste em banco**
- **Cronômetro + placar** durante a partida — também ferramentas temporárias em memória, **não persistem em banco**
- Registro de gols e assistências por partida (esses sim persistem, agregados ao perfil/ranking)
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
| **Racha** | A partida de segunda-feira. No código em inglês = `Match`. |
| **Mensalista** | Jogador com `player_type = monthly`. No MVP é só uma label organizacional (sem cobrança); quando pagamento voltar, será o jogador com assinatura ativa. |
| **Avulso** | Jogador com `player_type = casual`. No MVP é só uma label; quando pagamento voltar, será quem paga por partida. |
| **Presença** | Estado do jogador para um racha: `confirmed`, `declined`, `pending`. |
| **Lista de espera** | Confirmações além de `max_players`; primeiras na fila quando alguém cancela. |
| **Sorteio** | Algoritmo de balanceamento que distribui os confirmados em times. Resultado é volátil: vive só no app do admin durante a partida. |
| **Cronômetro** | Contador de tempo de jogo (in-app, em memória), com Iniciar/Pausar/Resetar. Não persiste. |
| **Placar** | Contador de gols por time (in-app, em memória), com +/- por time. Não persiste; gols individuais são registrados separadamente em `match_stats` no fim do jogo. |
| **Tombstone** | Marcador de deleção (`deleted_at`) propagado pela sincronização. |

## Princípios de produto

- **Caber no bolso do organizador na quadra.** O admin precisa rodar sorteio e lançar gols com luz ruim e às vezes sem rede. Por isso offline-first.
- **Convite, não cadastro aberto.** Jogadores entram por link mágico mandado pelo admin — não há signup público.
