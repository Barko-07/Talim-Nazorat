# A separate workspace for each specialist (requirement #3)

Each role works in its own workspace (`SpecialistWorkspace`), with its own modules, assessment areas, metrics, session templates and referral targets. The definitions are in `lib/core/constants/specialist_workspaces.dart`.

## Roles and workspaces

| Role (requirement) | `UserRole` | Edits | Views only |
|---|---|---|---|
| **Psychologist** | `psychologist` | Psychological tests and methods, Observations (emotions and behaviour), Access profile, Measurements, Sessions, Plan, Referrals | Subject level, Reports |
| **Speech therapist** | `speechTherapist` | Speech assessment, Access profile, Measurements, Sessions, Plan, Referrals | Subject level, Reports |
| **Defectologist** | `specialEducation` | Sensor-motor and practical development assessment, Access profile, Measurements, Sessions, Plan, Referrals | Subject level, Reports |
| **Special-education teacher** *(new role)* | `specialEdTeacher` | Subject knowledge level (DTS), **Subject tasks**, **Learning results**, Plan (writes it), Measurements, Sessions, Referrals | Reports |
| Subject teacher / class teacher | `teacher` | Subject level, Learning results, Measurements, Referrals | Students, Plan, Sessions |
| Coordinator | `coordinator` | School monitoring, Assigning specialists, Plan, Referrals, Subject level, Reports | Measurements, Sessions |
| School leadership | `institutionAdmin` | Users and roles, Assigning specialists, Reports | Monitoring, Plan, Referrals, Audit log |
| System admin | `superAdmin` | Users, Assigning specialists, Reports, **Importing DTS standards** | Monitoring, Audit log |
| Reviewer / methodologist | `reviewer` | — | Monitoring, Reports |
| Parent | `parent` | — | Closed for now; planned for the achievements passport |

Each specialist's own content:

| Specialist | Assessment areas (question bank) | Metrics | Session templates |
|---|---|---|---|
| Psychologist | Cognitive, Attention and memory, Emotional, Social, Behaviour | Attention span, Words recalled, Meltdowns per week, Conversations with peers | Psycho-correction, Social-skills training, Managing emotions, Parent consultation |
| Speech therapist | Speech and communication (sound pronunciation, phonemic hearing, active vocabulary, connected speech) | Correctly pronounced sounds, Active vocabulary, Reading speed | Articulation, Sound automation, Vocabulary and connected speech, Phonemic hearing |
| Defectologist | Sensor-motor development (fine motor, sensory standards, spatial orientation, self-care), Cognitive + **6-method library** (Seguin, Kohs, cut pictures, motor coordination, classification, self-care scale) | Fine motor (beads), Self-care, Independent tasks | Sensory integration, Fine motor, Self-care, Cognitive development |
| Special-education teacher | Learning skills (doing tasks independently, reading, writing) + DTS standards by subject | Reading speed, Independent tasks | Individual lesson at the child's level, Reading and writing, Arithmetic |

## Personal dashboard (`WorkspaceDashboard`)
Each specialist's home screen:
- **My students:** the children assigned to this specialist. A coordinator or the school leadership assigns them.
- **Not worked with yet:** children this specialist hasn't recorded any assessment, session, observation, measurement, subject level or task for. This covers part of requirement #6 for each specialist.
- **Needs attention:**
  - re-assessment due (more than 90 days since the last one)
  - **Decline** or **Ineffective** in the specialist's own metrics
  - open monitoring alerts
  - psychologist, speech therapist, defectologist: access profile not filled in
  - special-education teacher:
    - subject level not checked
    - **gap of 2+ grades** between the class grade and the actual level
    - **overdue tasks** with no result recorded
- **Incoming referrals:** referrals sent to this person, or to their role.
- **Sessions in the next 7 days.**

## Subject tasks and learning results (special-education teacher)
1. `suggestSubjectTasks` turns the child's next DTS standards into draft tasks. These are at the child's **actual level**, not their class grade.
2. The teacher edits a draft and gives it with `assignSubjectTask` (a due date is optional).
3. The result is recorded with `completeSubjectTask`: mastered / partial / not yet, plus a note.

## Status of the earlier ideas
- ✅ **Assigning children to specialists:** `assignSpecialistToStudent` / `unassignSpecialistFromStudent` (coordinator, leadership). Accepting a referral also assigns automatically.
- ✅ **Permissions enforced on every save** (#13). See [ARCHITECTURE.md](ARCHITECTURE.md).
- ✅ **Joint case conference:** `WorkspaceModule.caseConference`.
- ✅ **Achievements passport** (#11).
- ✅ **Per-specialist reports** (#12): `MonitoringReport.specialists`.
- ⏳ **Parent workspace:** the passport is ready on the backend. Parent accounts need a link to their child (guardians); to be done later.
- ⏳ **Tutor and medical-worker roles:** not added yet.
