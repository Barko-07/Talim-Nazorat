# How questions are chosen for a child

**Rule:** by default, a child gets the standard questions for **their grade**. Older grades get harder questions. The psychologist can adjust a child's working grade per skill area when needed. Questions the child can't do because of a disability are filtered out or marked for adaptation. A child keeps the same set for re-assessment, so their results can be compared over time.

The app only **suggests**. Every suggestion has a reason, and the psychologist always makes the final choice.

## 1. Grade (the default)
- The child's grade is read from `StudentModel.grade` (`'3-A'` → 3, `'10-B sinf'` → 10, `'Tayyorlov'` → 0). If it can't be read, the app estimates it from age: 7 years ≈ grade 1.
- Each question has a grade range: `minGrade`/`maxGrade`. Older questions without these fall back to the `'(1-4 sinf)'` text, then to the age range (age − 6). With no range at all, a question fits every grade. Observation questions are like this.
- Grade groups (`GradeBand`): preparatory, 1–2, 3–4, 5–6, 7–8, 9–11.

| Grade | Default standard questions |
|---|---|
| 1–4 | Primary questions + all-grade questions |
| 5–8 | Middle-school questions (analogies, proofreading attention, test anxiety, friendships, planning) + all-grade |
| 9–11 | Harder upper-grade questions (logical reasoning, main idea of a text, working memory, long attention, exam stress, naming emotions, career plans, independent living, decision-making, responsibility) + all-grade |

Every grade has at least one default question in each of the 5 skill areas.

## 2. Working grade (psychologist adjusts, optional)
When a child works below or above their grade in one skill area, the psychologist sets a working grade for that area (`StudentModel.domainLevels`). For example: grade 5, but memory at a grade 2 level. That area then uses grade 2 questions, and every other area stays on grade 5. Setting it back to `null` returns the child to their own grade.

After an assessment, `adviseLevelChange` makes a suggestion: a score ≤ 25% suggests one grade group lower, ≥ 90% one group higher, otherwise stay. It's only a suggestion.

## 3. What the child can do (access profile)
The psychologist fills this in (`StudentModel.accessProfile`): communication mode (verbal, limited speech, gesture/pointing, sign language, picture cards), plus hearing, vision, hand motor, reading and writing (full / partial / none).

Each question lists what it requires (`requirements`), and may say how to adapt it (`adaptationHint`).

| Child's ability | Result |
|---|---|
| full | suitable |
| partial | needs adaptation |
| none + the question has an adaptation | needs adaptation (the hint is shown) |
| none, no adaptation | not suitable, left out of the default set |

If the profile isn't filled in, or a question's requirements are unknown, nothing is excluded. A **warning** asks the psychologist to check by hand.

## 4. Re-assessment
`AssessmentPlanModel` is a child's saved question set for one skill area, together with the working grade it was built for. A new set replaces the active one, and the old set is kept as history. Re-assess with the active set. Only assessments with the same question set are compared as percentages (`areAssessmentsComparable`).

## 5. App updates
At startup, standard questions that are missing are added, and empty grade or requirement fields on existing standard questions are filled in. Questions written by psychologists are never changed.

## Permissions
- Access profile and working grade: psychologist, speech therapist or defectologist at the child's school, or the super admin. Teachers can't. Parents can be added later in `AccessControlService.developmentProfileEditors`.
- Question sets: anyone who can create assessments for that child.
