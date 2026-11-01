# Backend changes the UI needs to use

The backend team doesn't edit `lib/screens/`. This file lists what the UI should call. Newest changes are first.

---

## Defectologist methods library, licensed tests, data warnings

### 1. Each workspace shows its own methods library
`psychologist_methods_tab.dart` currently uses `PsychologicalMethodsData.methods` directly. Switch it to:
```dart
final methods = app.myMethods;   // psychologist → psychological, defectologist → defectology, leadership → all
m.profession.label;              // 'Psixologiya' / 'Defektologiya'
```
That way the same screen also works for the defectologist, who gets 6 methods: Seguin board, Kohs blocks, cut pictures, motor coordination (based on Ozeretsky), object classification, and a self-care scale.

### 2. Licensed tests: please show a warning
```dart
if (m.requiresLicensedMaterials) {
  // e.g. "⚠ Litsenziyalangan test" badge + m.licenseNote
}
```
Raven, WISC, Cattell CPQ and Yasyukova are copyrighted. Their score tables and labels like "Yuqori intellekt" have been **removed** from the app. Interpretation must use the official licensed manual.

### 3. Warn when saved records couldn't be read (optional, recommended)
```dart
final bad = LocalDbService().rejectedRowCounts;   // e.g. {'db_students': 1}
if (bad.isNotEmpty) { /* "N ta yozuv o‘qilmadi va zaxiraga olindi" banner for admin */ }
```
A single damaged record no longer hides the whole table. It's set aside in a backup, and the other records load normally.

### 4. Registration and password change
`auth.register(...)` and `auth.changePassword(...)` now return `{'success': false, 'message': ...}` on an error, and the loader no longer gets stuck. The existing screen code can show `message` as it does now.

---

## Speech therapist's sound tracker (new module: `WorkspaceModule.soundTracker`)

The rules are in [speech-sound-tracker.md](speech-sound-tracker.md). The speech therapist edits; the special-education teacher and coordinator can only view.

### 1. Sound tracker screen (on the child's profile)
```dart
final profile = app.speechProfile(student.id);
for (final p in profile.sounds) {                 // grouped by sound
  p.sound.display; p.sound.group.label;           // "r", "Sonor (r, l)"
  p.stage.label; p.completion;                    // current stage, 0..1 (progress bar)
  p.current.disorder.label; p.first.substitutedWith;   // starting problem, e.g. r → l
  p.daysAtCurrentStage(DateTime.now());
  p.dynamics.status.label; p.dynamics.reason;     // O‘sish / Pasayish / Samarasiz natija...
  app.soundNextStep(p);                           // next-step suggestion
  p.history;                                      // stage history (for a chart)
}
profile.mastered; profile.inProgress; profile.stuck;   // summary cards
```
Suggested display: show the sounds in their groups. Each sound gets a stage strip (stages 0–7) with the current stage highlighted. Show the sounds in `profile.stuck` in yellow at the top.

### 2. Recording a stage
```dart
await app.recordSoundEntry(SoundEntry(
  id: const Uuid().v4(), studentId: student.id, soundId: 'r',
  stage: SoundStage.staging,
  disorder: SoundDisorder.substitution, substitutedWith: 'l',   // only for a substitution
  differentiatedFrom: null,                                      // 'l' at the differentiation stage
  note: '...', recordedById: '', recordedByName: '',             // filled by backend
  recordedAt: DateTime.now(),
));
```
- Sound picker: `app.speechSounds`, grouped by `sound.group`.
- Stage picker: `SoundStage.values`. Problem type picker: `SoundDisorder.values`. All have `.label`.
- At the differentiation stage, offer `sound.confusedWith` as quick choices.
- Errors (`ValidationException`, `PermissionDeniedException`) come as readable text. Show `e.toString()`.

### 3. Already connected automatically
- The achievements passport, the speech therapist's dashboard ("sound isn't developing"), the red/yellow/green status and reports pick these records up automatically. No extra UI work is needed for that.

---

## Security, monitoring, achievements, reports, case conferences

The overall structure is in [ARCHITECTURE.md](ARCHITECTURE.md).

### ⚠️ Behaviour changes (please check)
1. **Specialists and teachers now see only their own children.** `app.students` returns only children assigned to them. The coordinator and leadership still see the whole school. This is required by #13.
2. **Every write is permission-checked.** A user without permission gets an error:
   ```dart
   try {
     await app.addObservation(obs);
   } on AppException catch (e) {
     showSnackBar(e.toString());   // readable Uzbek text, e.g. "Ruxsat cheklangan: ..."
   }
   ```
   Types: `PermissionDeniedException`, `NotFoundException`, `ValidationException` (import from `services/app_exceptions.dart`).
3. **A teacher can no longer edit a child's profile.** Only the coordinator and leadership can. Hide the edit button for teachers.
4. **Records are created under the logged-in user's name.** Assessments, observations and sessions are refused if they're created for someone else.
5. **Self-registration is limited to specialist roles** (psychologist, speech therapist, defectologist, special-education teacher, teacher).
6. **CSV exports:** values starting with `=`, `+`, `-` or `@` get a `'` in front, so Excel doesn't run them as formulas.

### 1. Monitoring: red / yellow / green (#6)
```dart
final m = app.monitoringSummary!;          // children visible to this user
m.count(StatusColor.red); m.count(StatusColor.yellow); m.count(StatusColor.green);
for (final s in m.statuses) {              // red first
  s.student; s.color.label; s.color.meaning;
  s.reasons;                               // why this colour (Uzbek text)
  s.lastWorkAt; s.specialistsNotStarted;
}
final one = app.childStatus(student);      // for the child profile
```
Use real colours: red `#DC2626`, yellow `#D97706`, green `#059669`.

### 2. Assigning specialists (coordinator / leadership)
```dart
await app.assignSpecialistToStudent(student.id, specialist.id);
await app.unassignSpecialistFromStudent(student.id, specialist.id, reason: '...');
```

### 3. "My achievements passport" (#11)
```dart
final p = app.achievementPassport(student.id);
for (final a in p.entries) {               // newest first
  a.category.label; a.title; a.description; a.achievedAt;
  a.isAutomatic;                           // true = derived from results; false = added by a specialist
}
await app.addAchievement(Achievement(
  id: const Uuid().v4(), studentId: student.id, category: AchievementCategory.social,
  title: 'Maktab tadbirida she’r o‘qidi', achievedAt: DateTime.now(),
));
await app.deleteAchievement(id);           // only the specialist who added it
```
Show it in a positive style, e.g. as cards.

### 4. Reports (#12)
```dart
final r = app.buildReport(from: start, to: end);   // defaults to the last 30 days
r.totalChildren; r.childrenWorkedWith; r.childrenNotWorkedWith; r.notWorkedWithNames;
r.statusCounts; r.workCounts; r.dynamicsCounts;
r.iepObjectivesTotal; r.iepObjectivesCompleted; r.iepCompletionRate;
r.referralsByStatus;
r.specialists;   // SpecialistActivity: fullName, role, childrenAssigned, childrenWorkedWith, coverage, recordsByKind, lastActivity
final csv1 = app.exportMonitoringReportCsv(from: start, to: end);
final csv2 = app.exportSpecialistActivityCsv(from: start, to: end);
```
A specialist sees only their own activity and their own children. Leadership sees everyone.

### 5. Case conference (new module: `WorkspaceModule.caseConference`)
```dart
await app.scheduleConference(CaseConference(
  id: const Uuid().v4(), studentId: student.id, studentName: '', agenda: '...',
  scheduledAt: date, convenedById: '', convenedByName: '',      // filled by backend
  participantIds: [psychologist.id, speechTherapist.id],        // at least 2
));
await app.addConferenceContribution(conf.id, summary: '...', recommendations: '...');  // participant
await app.finalizeConference(conf.id, conclusion: '...', decisions: [
  ConferenceDecision(id: const Uuid().v4(), text: '...', responsibleId: psy.id,
      responsibleName: '', dueDate: date),
]);                                                               // the organiser
await app.completeConferenceDecision(conf.id, decision.id);        // the responsible person
final list = app.conferencesFor(studentId: student.id);
conf.pendingParticipantIds;   // participants who haven't added findings yet
```

---

## Separate workspace for each specialist (#3)

The rules are in [specialist-workspaces.md](specialist-workspaces.md).

### 0. New role: `UserRole.specialEdTeacher` ("Maxsus ta’lim o‘qituvchisi")
- Code `SPECIAL_ED_TEACHER`, icon `Icons.school_rounded`. All the existing `UserRole` getters (label, icon, color…) support it.
- Add it to the role pickers: registration, the admin users screen, adding staff.
- Demo account (debug only, fresh install): `maxsus.oqituvchi@talim.uz`.

### 1. Build the menu from the workspace
Today `main_navigation_screen.dart` shows the same psychologist tabs to every non-admin role. Change it to:
```dart
final ws = app.workspace!;                 // the current user's workspace
ws.title; ws.mission;                      // heading and short description
for (final entry in ws.modules.entries) {  // the order is the menu order
  entry.key.title;                         // module name (Uzbek)
  entry.value;                             // ModuleAccess.view / edit
}
app.canUseModule(WorkspaceModule.subjectLevel, edit: true);  // show or hide the edit buttons
```
Suggested mapping from module to existing screens:

| Module | Screen |
|---|---|
| `psychAssessment` | psychologist assessments + methods tab |
| `speechAssessment` / `developmentAssessment` | the same assessment flow, with the question bank from `app.workspaceQuestionsFor(student)` |
| `observationJournal` | observations tab |
| `sessions` | sessions tab. Offer `ws.sessionTemplates` as quick choices |
| `measurements` | new: `app.workspaceMetrics` + the dynamics view |
| `subjectLevel`, `subjectTasks`, `learningResults` | new screens (see below) |
| `iep` | plans tab |
| `referrals` | referrals screen. Offer `ws.referralTargets` as the "to whom" list |
| `schoolMonitoring`, `userManagement`, `auditLog`, `curriculumAdmin` | admin portal tabs |

### 2. Workspace home page
```dart
final d = app.workspaceDashboard!;
d.caseload;            // my students
d.notWorkedWith;       // not worked with yet (show in red)
d.attention;           // AttentionItem: student, kind (.label), reason (Uzbek text)
d.incomingReferrals;   // referrals sent to me or my role
d.upcomingSessions;    // next 7 days
```

### 3. Subject tasks and learning results (special-education teacher)
```dart
final drafts = app.suggestSubjectTasks(student.id, 'Matematika');  // empty if the level isn't checked yet
await app.assignSubjectTask(drafts.first);    // or build your own SubjectTask(...)
await app.completeSubjectTask(task.id, Mastery.partial, note: '...');
final tasks = app.subjectTasksFor(student.id, subject: 'Matematika', onlyOpen: true);
```
Show `task.levelGrade` (e.g. "3-sinf darajasi") next to the task, so it's clear the task matches the child's actual level.

---

## Subject level (#9) and dynamics (#8)

The rules are in [subject-levels-and-dynamics.md](subject-levels-and-dynamics.md). All methods are on `AppProvider`.

### 1. Knowledge-level check (new screen for the special-education teacher)
```dart
final subjects = app.curriculumSubjects;                        // ['Matematika', 'Ona tili', ...]
final standards = app.curriculumStandards(subject: 'Matematika'); // grouped by s.grade
// The teacher marks each standard: Mastery.mastered / partial / notYet (.label is Uzbek text)
final preview = app.previewSubjectLevel('Matematika', results);   // suggested level before saving
final checkLower = app.subjectLevelNeedsLowerCheck('Matematika', results); // true → "also check lower grades"
final saved = await app.saveSubjectLevel(
  studentId: student.id, subject: 'Matematika', results: results,
  confirmedGrade: teacherChoice,   // optional; defaults to the suggestion
);
```
- Start from the child's class grade and go down until the standards are mastered.
- Throws `Exception` for users who aren't allowed (psychologist, reviewer). Show the message.
- Standards with `isOfficial == false` are samples. Show a small "sample" label next to them.

### 2. Child profile: class grade vs actual level
```dart
final level = app.currentSubjectLevel(student.id, 'Matematika');   // null = not checked yet
app.describeSubjectLevel(level!);  // "7-sinf o‘quvchisi, Matematika: 3-sinf darajasi (sinfidan 4 sinf past)"
level.classGrade; level.confirmedGrade; level.gap;
final next = app.nextStandardsFor(student.id, 'Matematika');      // tasks / plan goals to work on next
```
Show the class grade and the actual level **separately**, as the requirement asks.

### 3. Recording measurements with units
```dart
final metrics = app.progressMetrics;   // name, unit, higherIsBetter
await app.addMeasurement(ProgressMeasurement(
  id: const Uuid().v4(), studentId: student.id, metricId: metric.id,
  value: 5, measuredAt: DateTime.now(), recordedById: '', recordedByName: '', // filled by backend
  note: '...', iepObjectiveId: objective?.id,   // optional link to a plan goal
));
await app.addCustomMetric(ProgressMetric(id: const Uuid().v4(), name: '...', unit: '...', domain: '...'));
```

### 4. Dynamics monitoring view
```dart
final r = app.measurementDynamics(student.id, metric.id, period: DynamicsPeriod.month);
// also: app.subjectLevelDynamics(student.id, 'Matematika')
//       app.assessmentDynamics(student.id, plan.questionIds)
r.status.label;     // 'O‘sish' / 'Pasayish' / 'Barqaror holat' / 'Samarasiz natija' / 'Ma’lumot yetarli emas'
r.reason;           // e.g. "Oldingi natijaga nisbatan ijobiy o‘zgarish: 2 daqiqa → 5 daqiqa."
r.series;           // List<DataPoint>(at, value) for the chart (fl_chart)
r.change; r.changePercent;
```
Offer a period switch: per measurement / monthly / quarterly.

---

## Question selection by grade, working grade and ability

The logic behind this is in [question-selection.md](question-selection.md). All new methods are on `AppProvider`.

### 1. Default questions when starting an assessment
`lib/screens/psychologist/assessment/create_assessment_flow.dart` → `_isRecommended()` currently matches grade text, so any grade containing "1" counts as primary school. Replace it with:

```dart
// Preselect these — the child's default set for their grade:
final defaults = app.defaultQuestionsForStudent(student, domain: selectedDomain);

// Full list for the "add more questions" view, best fits first:
final all = app.rankQuestionsForStudent(student, domain: selectedDomain);
// each QuestionFit has:
//   fit.question       – AssessmentQuestionModel
//   fit.suitability    – suitable / needsAdaptation / unsuitable (.label is Uzbek text)
//   fit.gradeMatches   – fits the child's (working) grade
//   fit.isRecommended  – not unsuitable AND grade matches
//   fit.reasons        – List<String>, show these to the psychologist
//   fit.warnings       – List<String>, e.g. "profile not filled"
```
Suggested display: give "needs adaptation" a note showing `reasons`. Show "not suitable" and other-grade questions greyed out but still selectable, because the psychologist decides.

### 2. Working grade per skill area (optional, on the student profile)
```dart
final grade = app.workingGradeFor(student, domain);          // the child's own grade unless adjusted
final adjusted = student.domainLevels.containsKey(domain);  // true = psychologist changed it
await app.setStudentWorkingGrade(student.id, domain, 2, note: '...');   // works at grade 2 level
await app.setStudentWorkingGrade(student.id, domain, null);             // back to own grade
```
Show it with `GradeBand.gradeLabel(grade)` (e.g. "2-sinf"). Only show "adjusted" when `adjusted` is true.

### 3. Access profile form (new, on the student profile)
```dart
await app.updateStudentAccessProfile(student.id, StudentAccessProfile(
  communicationMode: CommunicationMode.signLanguage,
  hearing: AbilityLevel.none,
  vision: AbilityLevel.full,
  handMotor: AbilityLevel.full,
  reading: AbilityLevel.partial,
  writing: AbilityLevel.partial,
  notes: '...',
  updatedAt: DateTime.now(),
));
```
- Read the current values from `student.accessProfile`. It's `null` if not filled in yet, so show a "fill in" prompt.
- Dropdowns: `CommunicationMode.values` / `AbilityLevel.values`, each with `.label`.
- It throws `Exception` if the user isn't allowed (e.g. a teacher). Show the message.

### 4. Personal question set (re-assessment)
```dart
final plan = app.activeAssessmentPlan(student.id, domain);   // null = none yet
await app.saveAssessmentPlan(AssessmentPlanModel(
  id: const Uuid().v4(), studentId: student.id, domain: domain,
  workingGrade: app.workingGradeFor(student, domain),
  questionIds: selectedIds,
  createdById: '', createdByName: '', createdAt: DateTime.now(), // filled by backend
));
final history = app.assessmentPlansFor(student.id, domain: domain);
```
When starting a re-assessment, preselect `plan.questionIds`, not the defaults.

### 5. After an assessment
```dart
final advice = app.adviseLevelChange(assessment, app.workingGradeFor(student, domain));
// advice.suggestion: lower / keep / higher; advice.suggestedGrade; advice.reason (Uzbek text)
```
Show `advice.reason` with a button that calls `setStudentWorkingGrade(...)`. Never change the grade automatically.

### 6. Comparing two assessments
`assessment_compare_dialog.dart`: call `app.areAssessmentsComparable(a, b)` before showing a percentage change. If it's `false`, show "different question set" instead of a % difference.

### 7. Question editor (optional)
Questions now have `minGrade` / `maxGrade` (ints, 0–11), `requirements` (`Set<QuestionRequirement>`) and `adaptationHint`. The editor can offer these fields. If left empty, the backend falls back to the age text, and the selection shows a "check manually" warning.
