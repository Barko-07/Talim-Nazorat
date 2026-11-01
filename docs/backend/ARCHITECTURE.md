# TA’LIM NAZORAT backend: architecture

This is the backend of the Flutter app: models, services and providers. Screens (`lib/screens/`) never touch storage directly. They always go through `AppProvider`.

```
Screens ──► AppProvider (current user, notifyListeners)
               │
               ├─► Logic services (pure Dart, testable)
               │     QuestionSelectionService · SubjectLevelService · DynamicsService
               │     WorkspaceService · ChildStatusService · AchievementService · ReportService
               │     SoundTrackerService
               │
               └─► LocalDbService (storage + permission checks + audit log)
                      └─► AccessControlService (permission matrix, single source of truth)
```

## Rules every backend change follows
1. **Every write needs a user.** All write methods in `LocalDbService` take a required `byUser` and check permissions *before* changing anything. `AppProvider` always passes the logged-in user (`_requireUser()`).
2. **Visibility:**
   - Specialists and teachers see only the children assigned to them.
   - The coordinator, school leadership and reviewer see their whole school.
   - The system admin sees everything.
   - When a specialist accepts a referral, they're automatically assigned to that child.
3. **Records are always created under the real user's name.** For example, a referral's sender is set by the backend, not taken from the UI.
4. **Typed errors** (`lib/services/app_exceptions.dart`):
   - `PermissionDeniedException`: no permission. The message starts with "Ruxsat cheklangan: …".
   - `NotFoundException`: the record doesn't exist.
   - `ValidationException`: invalid data.

   `toString()` returns a readable Uzbek message, so the UI can show `e.toString()` as it is.
5. **Every important change goes into the audit log** (who, role, action, entity, details), with no passwords.
6. **Saved data is protected:**
   - A table that can't be read at all is backed up and never overwritten.
   - A single damaged row doesn't hide the others: it's moved to the `<table>_rejected_rows` backup, and `rejectedRowCounts` reports it.
   - The audit log writes only its own table, so a save doesn't rewrite the whole database twice.
   - When nobody is logged in, `AppProvider` reads as an inactive anonymous user and gets no data.
   - New fields have defaults in `fromJson`, so data saved by older versions still loads.
   - `init()` always starts from a clean in-memory state.
7. **The app suggests; specialists decide.** Statuses, levels and question choices are suggestions, and each comes with a reason.

## Permission matrix (short version)
| Action | Who |
|---|---|
| Add or edit a child | Coordinator, school leadership (own school), system admin |
| Archive a child | School leadership, system admin |
| Assign / unassign a specialist | Coordinator, school leadership |
| Assessments, measurements, sessions | Specialist assigned to the child (under their own name) |
| Psychological observation | Psychologist assigned to the child; only psychologists see confidential ones |
| Access profile, working grade | Psychologist, speech therapist, defectologist (assigned) |
| Subject level, subject tasks | Special-education teacher, teacher, defectologist (assigned), coordinator |
| Individual plan | Coordinator, leadership, special-education teacher; the responsible person updates the goals |
| Sound tracker | The speech therapist assigned to the child (anyone who can see the child can view it) |
| Case conference | Coordinator or leadership convenes; participants add findings; the organiser concludes |
| Standard questions | System admin only (specialists' own questions: the author) |
| Users | System admin; school leadership (own school only). A user can't change their own role, school or status |
| Self-registration | Specialist roles only |

## Storage tables (SharedPreferences, JSON)
| Key | Contents |
|---|---|
| `db_users`, `db_students` | Users (hashed passwords), children (access profile, working grade) |
| `db_assessments`, `db_questions`, `db_assessment_plans` | Assessments, question bank, personal question sets |
| `db_sessions`, `db_observations`, `db_iep` | Sessions, psychological observations, individual plans |
| `db_curriculum`, `db_subject_levels`, `db_subject_tasks` | DTS standards, subject levels, subject tasks |
| `db_measurements`, `db_custom_metrics` | Measurements with units, custom metrics |
| `db_achievements`, `db_conferences` | Manual achievements, case conferences |
| `db_sound_entries` | The speech therapist's sound tracker (stage history) |
| `db_referrals`, `db_alerts`, `db_notifications`, `db_audit` | Referrals, monitoring alerts, notifications, audit log |

## Services
| Service | Requirement | What it does |
|---|---|---|
| `QuestionSelectionService` | #4 | Default questions by grade, filtered by disability, working grade |
| `SubjectLevelService` | #9 | Actual level from DTS standards, next standards |
| `DynamicsService` | #8 | Growth / decline / stable / ineffective, monthly and quarterly views |
| `WorkspaceService` | #3 | Workspace per specialist, personal dashboard |
| `ChildStatusService` | #6 | Red / yellow / green status with written criteria |
| `AchievementService` | #11 | Achievements passport (manual + automatic) |
| `ReportService` | #12 | School and per-specialist reports, CSV |
| `MethodLibrary` | #4 | Methods by specialty (psychology, defectology); licensed tests are flagged |
| `SoundTrackerService` | #3, #8 | Speech therapist's sound tracker: stages, dynamics, next step |

## Tests
`flutter test` runs 200 tests (including `data_integrity_test.dart`, which checks that every reference in the demo data points to an existing record). Test files are in `test/`. Security rules have their own file: `test/authorization_test.dart`.

## Known limitation
Data lives only on the device. Sharing data between specialists and leadership for real needs a server (see the server discussion). The service layer is written so the same rules can later move to a server.
