# EGO — Estado do Projeto (Handoff para novo chat)

> Documento vivo que resume TUDO até aqui. Cole isto (ou diga "leia ESTADO-DO-PROJETO.md")
> ao iniciar um chat novo para retomar com contexto completo. Última atualização: Fase 1 concluída.

---

## 1. O que é o EGO
App **iOS nativo (iOS 17+, Swift/SwiftUI)** de foco e estudos para estudantes brasileiros de
**vestibular/ENEM**. Junta: Pomodoro, Modo Foco (bloqueio de apps via Screen Time), streak estilo
Duolingo, **mascote pixel interativo (um sapo)**, rotinas de estudo, banco de questões, estruturas
de redação, metas por tópico e stats compartilháveis. Vende **constância e resultado**, não "um timer".

## 2. Decisões travadas
- **Stack:** Swift 5.9+, SwiftUI, **SwiftData + CloudKit (private DB) desde o dia 1**, Swift
  Concurrency, FamilyControls/ManagedSettings/DeviceActivity (Modo Foco), WidgetKit/ActivityKit.
- **Arquitetura:** MVVM + módulos por feature. Views burras; ViewModels com `@Observable`;
  repositórios donos da persistência (ViewModels nunca importam SwiftData direto).
- **Idioma:** interface em **PT-BR** (via `Localizable.xcstrings`, sem strings hard-coded);
  código/comentários/docs em **inglês**.
- **Design:** estilo **Notion — claro, minimalista**. Paleta **travada** (verde-led):
  verde `#3DA35D`, verde profundo `#256B3E`, verde suave `#E7F4EA`, âmbar streak `#F5A524`,
  teal foco `#2FA5A5`, coral erro `#E5533D` + neutros. Fontes ainda em SF Pro (placeholder).
- **Mascote:** um **sapo** verde-oliva em pixel-art estilo "companion do Claude", perfil, com
  **chapéu de explorador** (conforme a referência do usuário). Animações: idle, estudando,
  feliz (pulo), triste, dormindo (com "z"), worried, levelUp. Protótipo em `assets/mascot/`.
- **Ferramentas de build:** Xcode + Claude no terminal (Fable/Sonnet no geral, **Opus cirúrgico**).

## 3. Documentação do projeto (pasta `EGO - ESTUDO/`)
- `README.md` — índice geral.
- `QUICKSTART.md` — passo a passo pra iniciar (Xcode + terminal + primeiro prompt).
- `CLAUDE.md` — regras do projeto (carregado automático pelo Claude no terminal).
- `docs/00-PRD.md` — visão, personas, métricas.
- `docs/01-FEATURES.md` — todas as features com IDs **F-01…F-18** (fonte da verdade de comportamento).
- `docs/02-ARCHITECTURE.md` — stack, módulos, layout de pastas.
- `docs/03-DATA-MODEL.md` — entidades SwiftData/CloudKit (**regra: toda relação precisa de inversa**).
- `docs/04-DESIGN-SYSTEM.md` — tokens (paleta verde travada), tipografia, componentes.
- `docs/05-MASCOT.md` — sapo: conceito, estados, sistema de animação.
- `docs/06-SCREEN-TIME-FOCUS.md` — Modo Foco (bloqueio) + entitlement + fallback soft-focus.
- `docs/07-GAMIFICATION.md` — streak, XP, moedas, stats, story cards.
- `docs/08-CONTENT-BANKS.md` — banco de questões, redação, rotinas (+ licenciamento).
- `docs/09-ROADMAP.md` — plano por fases.
- `docs/10-COMPETITIVE-RESEARCH.md` — benchmark internacional + fontes.
- `assets/mascot/` — `frog-prototype.html` (animação) + `MASCOT-ANIMATION-REFERENCE.md` (port SwiftUI).
- `prompts/FABLE5-INIT-PROMPT.md` — prompt otimizado de arranque.

## 4. Linha do tempo — o que já foi feito

**Preparação (Cowork):** pesquisa internacional (Forest, Duolingo, Finch, Study Bunny, Anki…),
que validou e adicionou features (economia de moedas, XP/níveis, streak freeze, co-study, SM-2,
widgets). Toda a documentação acima foi escrita. Mascote definido como sapo + protótipo animado.

**Fase 0 — Fundações ✅** Estrutura de pastas, design tokens (paleta verde), SwiftData + CloudKit,
DI (`DIContainer`), app shell (TabView: Início/Estudar/Estatísticas/Perfil), onboarding skeleton.
Build + testes verdes; app abre no simulador.

**Fase 1 — Loop central do hábito ✅ (COMPLETA)**
- *Fatia 1:* **F-01 Pomodoro** (máquina de estados, presets, sessão anexável a matéria, timer por
  datas), **F-13 Mascote** (sapo procedural em SwiftUI Canvas: `FrogPose` + `MascotAnimator` +
  `FrogRenderer` + `MascotEventCenter`), **F-04 Streak** (`StreakLogic`, com freeze), **F-14
  XP/moedas** (`GamificationLogic`). Orquestração via `SessionCompletionService`.
- *Fatia 2:* Feedback pós-sessão (sheet com sapo comemorando, XP/moedas/level-up), **Wallet +
  CoinTransaction** (ledger append-only, migração do saldo legado), mascote **worried** ligado ao
  risco de streak, rollups por matéria (`SubjectStat`) transacionais.
- *Fatia 3:* **F-03/F-09 Notificações** locais (lembrete diário, streak-em-risco 20h, comeback,
  quiet hours, frases PT-BR na voz do sapo), **freeze** (ganhar por milestone + comprar com moedas),
  estado **levelUp** do mascote.
- *Live Activity:* **F-16** Pomodoro na Dynamic Island + Lock Screen (widget target + App Group
  `group.com.ego.EGO`, arte do sapo compartilhada via exception sets).
- **Status de testes:** 85 unitários + 5 de UI passando. Sugerido: `git tag v0.1-phase1`.

## 5. Bugs importantes encontrados e lições
- **Crash (CloudKit):** relação `SubjectStat.stats → UserStats?` estava **sem inversa**. CloudKit
  exige `@Relationship(inverse:)` em toda relação; o store real falhava. **Lição travada nos docs:**
  toda relação precisa de inversa, e **sempre rodar 1 teste contra `ModelContainer` real** (não só
  in-memory) após mudar schema — mocks escondem esse erro.
- **Task fire-and-forget com container morto** em `sessionDidComplete` — removido.
- **Container in-memory morrendo no host de testes** — segurado com `withExtendedLifetime`.
- **`Calendar.ordinality` instável sob carga** — trocado por contagem via `startOfDay`.
- **Info.plist do widget duplicado** no build — resolvido com exception set.

## 6. Onde estamos AGORA
**Fase 1 100% concluída e testada.** Próximo bloco é a **Fase 2 — Modo Foco (bloqueio de apps) +
rotinas + metas**. Estratégia definida: construir primeiro o que **não** depende de aprovação da
Apple; deixar o bloqueio real por último (precisa de entitlement + iPhone físico).

### Próximo passo concreto — Fase 2, fatia 1 (desbloqueada)
Prompt pronto pra colar no terminal (começa pelo PLANO, sem código, espera "go"):
```
Fase 2, fatia 1 (sem depender de entitlement). Leia docs/01-FEATURES (F-05, F-06, F-10),
docs/06 §7 (soft-focus) e docs/03 antes. Lembre: toda relação SwiftData precisa de inversa
(@Relationship(inverse:)) e rode um teste contra ModelContainer real após mudar schema.

Implemente, seguindo MVVM + repositórios e a paleta travada:
- F-05 Rotinas de estudo (builder semanal: blocos por dia com matéria/duração/sessões)
  + templates (ENEM 6 meses, intensivo, revisão).
- F-06 Histórico de rotina (RoutineLog append-only, 6 meses) + tendências básicas.
- F-10 Metas por tópico (horas/questões/prazo), progresso alimentado pelas sessões.
- Soft-focus fallback: modo foco dentro do app com o sapo "guardando", penalizando
  streak se sair no meio (sem bloqueio de sistema ainda).

Regras: comece pelo PLANO (arquivos, entidades novas + inversas, o que muda no schema),
sem código, e espere meu "go". Copy PT-BR via xcstrings, tokens de design, teste a lógica.
```
Depois disso (quando a entitlement chegar + em device): **F-02 bloqueio real via Screen Time** —
rodar no **Opus**. Em paralelo seguem as fases seguintes do roadmap (banco de questões, redação,
social/widgets, polish).

## 7. Pendências do usuário (fora do código)
- [ ] **Aplicar a entitlement Family Controls** no portal Apple — **urgente**, a aprovação demora e
  trava o bloqueio de apps (Fase 2).
- [ ] **Conta Apple Developer paga (US$99/ano)** + **iPhone físico** para testar CloudKit sync e o
  bloqueio real (não funcionam bem no simulador).
- [ ] Registrar o **App Group `group.com.ego.EGO`** no portal e habilitar nos 2 targets ao assinar
  pra device (no simulador já funciona).
- [ ] (Opcional) Padronizar identificador: bundle ficou `com.ego.EGO` (org inicial era `com.akai`).

## 8. Como trabalhamos (regras de fluxo — manter)
1. **Uma fatia por vez**, sempre começando pelo **PLANO antes do código**; revisar o plano antes do "go".
2. **Testar de verdade** (playthrough no simulador) + **commit + tag** a cada fatia verde.
3. **Definição de pronto:** funciona offline, sincroniza via CloudKit, mascote reage, stats
   atualizam, copy PT-BR, segue o design system, tem teste pra lógica não-trivial.
4. **Economia de limite no terminal:** **Sonnet/Fable como padrão, Opus só cirúrgico**; **`/clear`
   entre fatias** (o `CLAUDE.md` + `/docs` recarregam baratos); **não colar logs/crash gigantes** —
   apontar o arquivo pro agente ler; prompts escopados; `.claudeignore` pra não indexar `DerivedData`/build.
5. Após qualquer mudança de schema: rodar teste contra **ModelContainer real** e conferir **inversas**.

## 9. Como retomar num chat novo
1. Abra o projeto no terminal: `cd ~/Documents/akai/"EGO - ESTUDO"` e rode `claude` (`/model` →
   Sonnet como padrão). O `CLAUDE.md` + `/docs` carregam sozinhos.
2. No chat (aqui no Cowork ou no terminal), diga: *"Leia ESTADO-DO-PROJETO.md — estamos concluindo a
   Fase 1, próximo é a Fase 2 fatia 1 (rotinas + metas + soft-focus)."*
3. Cole o prompt da seção 6 e siga o fluxo (plano → go → testar → commit).
```
