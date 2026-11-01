# Speech therapist's sound tracker (logopedik tovushlar kartasi)

The speech therapist records each target sound's stage of correction. Every change is kept as history, so each sound gets its own progress line.

## Sound stages (`SoundStage`, in order)
| # | Stage | Meaning |
|---|---|---|
| 0 | Preparation | Articulation exercises |
| 1 | Setting the sound | The sound is produced correctly on its own |
| 2 | Automation: syllables | |
| 3 | Automation: words | |
| 4 | Automation: sentences | |
| 5 | Automation: text and storytelling | |
| 6 | Differentiation | Telling it apart from similar sounds (r–l, s–sh, z–j…) |
| 7 | **Correct in free speech** | The goal: the sound is "mastered" |

## The type of problem (`SoundDisorder`)
- normal
- **leaves it out**
- **swaps it** for another sound: the replacement must be given, e.g. r → l
- **distorts it**

A sound that's correct in free speech can't have a problem recorded against it.

## Sound inventory
All Uzbek sounds are included (`UzbekSpeechSounds`), grouped the way speech therapists group them:
- vowels
- whistling (s, z)
- hissing (sh, j, ch)
- sonorant (r, l)
- back-lingual (k, g, q, g‘, x, h)
- other consonants

Each sound comes with its usual confusion pairs. These are used for the differentiation step.

## What the app works out
- **Each sound's progress:** current stage, how many days it has been at that stage, completion (0–100%), history.
- **Dynamics:**
  - moving up a stage → **Growth**
  - moving back → **Decline**
  - 3 records over 30+ days at the same stage → **Ineffective** ("the sound isn't developing")
  - a sound that stays correct in free speech is **Stable**, not "stuck"
- **Next-step suggestion:** e.g. "Next stage: differentiation, telling r apart from l and y".
- **Links to existing features:**
  - **Achievements passport:** "The r sound is set", "The r sound is correct in free speech"
  - **Speech therapist's dashboard:** a "sound isn't developing" warning
  - **Red/yellow/green status:** a stuck or declining sound gives yellow; a recent stage gain counts as a positive result
  - **Reports:** each record counts as work with the child

## Permissions
- **Recording:** the speech therapist assigned to the child, or the system admin.
- **Viewing:** anyone who can see the child, e.g. the psychologist or special-education teacher assigned to the same child, or the coordinator.
- Records are never deleted. The backend always saves them under the logged-in therapist's name.
