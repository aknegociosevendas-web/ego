# 08 — Content Banks (Questions, Essays, Routines)

Covers the study-content features: F-07 question bank, F-08 essays, and F-05/06 routine templates.
The biggest open item here is **content sourcing & licensing**.

## 1. Vestibular/ENEM question bank (F-07)

### Data shape
`Question` entities (see `03-DATA-MODEL.md`): exam, year, subject, topic, difficulty, statement,
options, correct index, explanation, source, licenseNote.

### Sourcing options (must resolve before Phase 3)
1. **ENEM / INEP public items** — ENEM past exams are published by INEP (government). Generally the
   **most defensible** source. Still verify redistribution terms and attribute the source/year.
2. **Original items** — commission/author original questions modeled on exam style. Fully owned,
   no licensing risk; higher production cost.
3. **Licensed partner content** — partner with a cursinho/editora for their bank (revenue share).
4. **AI-assisted generation** — generate practice items, **human-reviewed**, tagged as "inspired
   by" not copied. Never reproduce copyrighted questions verbatim.

> ⚠️ Many vestibular banks (FUVEST, UNICAMP, etc.) are **copyrighted**. Do not scrape/redistribute
> without permission. Start with ENEM/INEP + original items; expand via licensing.

### Content pipeline
- Author/import in a structured format (JSON) → validation script → bundle in-app (seed) and/or
  sync via CloudKit **public database** for updates without an app release.
- Versioned content packs by subject/exam so the bank grows over time.

### Practice UX
- Filter by exam/year/subject/topic/difficulty; timed or untimed.
- Answer → immediate feedback + explanation → mark for review.
- Wrong/marked questions enter the **SM-2 review queue** (`ReviewItem`).
- Per-topic accuracy feeds `SubjectStat`, goals, and routine suggestions.

### Spaced repetition (SM-2)
- Standard SM-2: grade 0–5 → update `easeFactor`, `interval`, `repetitions`, `dueDate`.
- Daily "revisão" queue surfaces due items. Unit-test the scheduler.

## 2. Essay frameworks (F-08)

### Templates (`EssayTemplate`)
- **ENEM dissertativo-argumentativo**: introdução (contextualização + tese), 2 parágrafos de
  desenvolvimento (argumento + repertório + análise), conclusão com **proposta de intervenção**
  (agente, ação, meio/modo, finalidade, detalhamento).
- Vestibular variants (dissertação, carta, etc.) as additional templates.

### Rubric (`Rubric`) — ENEM 5 competências
1. Domínio da norma culta
2. Compreensão da proposta / estrutura dissertativo-argumentativa
3. Seleção e organização de argumentos
4. Mecanismos linguísticos (coesão)
5. Proposta de intervenção (respeito aos direitos humanos)
Each 0–200 → total /1000. Self-score UI maps to these.

### Repertório / argument bank
- Curated `EssayFlashcard`s (dados, citações, fatos históricos, filmes, leis) by theme.
- Connectives list; competency checklist while writing.
- Repertório cards can enter the SM-2 queue for memorization.

### Writing UX
- Template scaffold + free-write area, word count, timer, drafts (`EssayDraft`).
- Self-score against rubric; track essays finished in stats/goals.

## 3. Routine templates (F-05/06)

Prebuilt `Routine` templates the user can adopt and customize:
- **ENEM 6 meses** (balanced across areas + redação + revisão).
- **ENEM intensivo (reta final)**.
- **Concurso** (edital-driven blocks).
- **Universitário** (por disciplina).
- **Revisão pré-prova**.

Each template = a set of `RoutineBlock`s by weekday/subject/target. History (`RoutineLog`, 6 months)
lets EGO suggest adjustments ("você rende mais de manhã em exatas").

## 4. Localization & tone

All content PT-BR. Explanations clear and student-friendly. Mascot can "comment" on results
(encouraging, never mocking).

## 5. Open decisions
- [ ] Confirm question-bank sourcing strategy (ENEM/INEP + original vs licensing partner).
- [ ] Define content-pack format + update channel (bundled vs CloudKit public DB).
- [ ] Legal review of any third-party exam content before shipping.
