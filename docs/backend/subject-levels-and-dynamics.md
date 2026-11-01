# Subject level and development dynamics

Covers requirement #9 (comparison with state education standards) and requirement #8 (development dynamics).

## #9: Actual subject level compared with the class grade

**Example from the requirements:** a grade 7 student whose maths matches the grade 3 curriculum. The app stores the **class grade (7)** and the **actual level (3)** separately, and shows the difference.

### How it works
1. Each subject has **standards per grade** (`CurriculumStandard`): what a child should know or be able to do by the end of that grade.
2. The special-education teacher (or the class teacher, or a coordinator) marks each standard as **mastered / partial / not yet** (`Mastery`).
3. The app **suggests** a level: the highest grade whose standards are ≥ 80% mastered, where a partial counts as half. Every checked grade below it must also be mastered.
4. The teacher **confirms** the level, or sets a different one. Only the confirmed level is used from then on.
5. If the lowest grade checked isn't mastered either, the app asks for a lower grade to be checked. For example: the child only tried grade 7 standards and failed. The real level could be grade 3, so the app won't claim grade 6.
6. **Next standards** (`nextStandardsFor`) are the unmastered standards at the current and next grade. These are what tasks and individual-plan goals should target.
7. Every check is kept, so the subject level also has its own dynamics.

### ⚠️ The standards are currently samples
The app ships with **sample** standards for Mother tongue (grades 1–7), Mathematics (grades 1–7) and Reading (grades 1–4). They're marked `isOfficial: false`. They are **not the official state standards (DTS) text**.

Once the official standards are available, the system admin loads them with `importCurriculumStandards()`. For each subject that's imported, the samples are removed, and they don't come back.

**Needed from you or the ministry:** the official state standards (DTS) / learning outcomes, by subject and grade.

### Permissions
- **Recording a subject level:** special-education teacher, class teacher or coordinator at the child's school, or the super admin. Psychologists and reviewers can only view.
- **Importing standards:** super admin only.

## #8: Development dynamics

### Results with units
Results aren't only scores. A `ProgressMeasurement` records a value **with its unit** against a `ProgressMetric`, so "2 minutes → 5 minutes" can be recorded and shown.

Standard metrics:

| Metric | Unit | Improves when |
|---|---|---|
| Attention span on one task | minutes | ↑ |
| Words recalled out of 10 | words | ↑ |
| Tasks done independently (out of 5) | tasks | ↑ |
| Reading speed | words/min | ↑ |
| Emotional meltdowns per week | times | ↓ (fewer is better) |
| Conversations started with peers | times | ↑ |

Specialists can add their own metrics with `addCustomMetric`.

### Statuses (`DynamicsService`)

| Status | Rule |
|---|---|
| **Growth** (O‘sish) | The latest result is better than the previous one by more than 10% |
| **Decline** (Pasayish) | The latest result is worse than the previous one by more than 10% |
| **Stable** (Barqaror holat) | The change is within 10% |
| **Ineffective** (Samarasiz natija) | The last 3 results, spread over at least 30 days, show no meaningful improvement. The support being given should be reviewed |
| **Not enough data** | Fewer than 2 results |

When more than one rule matches, the order is: Decline > Ineffective > Growth / Stable.

Results can be compared **per measurement, per month or per quarter** (`DynamicsPeriod`). For a month or quarter, the last result in that period is used.

The same engine runs on three kinds of data:
- measurements (`measurementDynamics`)
- subject levels (`subjectLevelDynamics`), where a change of one whole grade counts as significant
- assessments that used the same question set (`assessmentDynamics`)
