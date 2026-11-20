# PAT @ Whiz Kids

Portable Access to Therapy: the shared PAT Base application for authorised families and therapy teams.

[Open PAT Base](https://whizkidal.github.io/PAT-WhizKids/portable-practice.html)

## Repository boundary

This repository contains reusable application code, generic icons, database schema and tests only. Participant configurations, personalised images, recordings and records belong in the dedicated PAT Supabase project, protected by sign-in and row-level access rules. Formal clinical documents belong in SharePoint / Halaxy. Never commit participant backups or credentials.

The same application supports each participant's private configuration and the generic template. The therapy gateway opens Speech, OT, PBS and School; participant-specific branding and interests are loaded privately.

## Setup and checks

See [the setup guide](PORTABLE_PRACTICE_README.md). Run npm ci followed by npm test. Publish the main branch root with GitHub Pages. Add the published page to the PAT project's authentication redirect allowlist before moving sign-in links.

## Parent practice plans — November 2026

Apply `supabase/reward_policy.sql`, then `supabase/reward_plan_v4.sql`. The latter permits authenticated parents and clinicians to manage tasks and future practice plans. The child account can record work but cannot edit allowances or approve rewards. Each full 15 minutes of parent-confirmed practice earns one coin up to a shared weekly allowance. The completion bonus needs the planned number of sessions and allowance; a separate later session enables the extra-work bonus. Both bonuses unlock from Sunday and need parent approval. Existing records keep their previous rules; a week containing records cannot have its saved targets or plan rewritten. A new minute plan requires explicit parent activation in Family setup.

Run `tests/minute-plan.test.cjs` alongside the legacy reward, cloud, install, Help and updater tests. Test database permissions in a rolled-back transaction; do not retain fictional participant records.

Apply `supabase/help_message.sql` before deploying the updated `pat-help` function. The optional message is at most 500 characters, is bound to the request identity for retries, and is sent only to the server-configured parent. No raw dictation audio is emailed. The function validates the bearer token itself, as before. Browser dictation support varies and may use a remote browser speech service; keyboard dictation and typing remain alternatives.

Story Safari is maintained separately in Therapy-Games. Its optional familiar-voice clips stay in that browser's IndexedDB, with explicit export/import; they are not automatically part of PAT cloud audio.

## Migration from Track

PAT was extracted from WhizkidAl/Track-WhizKids at commit 043f82f0ad83ab982c665c4900402a68225093d9 on 14 November 2026. Track remains a separate application and repository. The old PAT address remains available for existing tablet shortcuts during migration. The database, accounts and participant records are unchanged. Check Saved to cloud before replacing a tablet shortcut.

The complete parent guide is available inside Family setup and in `parent-guide.html`. Parents can edit Explore/Make labels, emojis, HTTPS links, visibility and custom choices, plus preset colour themes and card text size. Practice plans are managed separately in the parent-only Weekly practice plan panel. Team invitation drafts are parent-authored.

## Installed-app updates

The installed app checks for a newer release on resume, online recovery, return to Home and once per minute while visible. It validates released asset hashes before reloading. Updates wait for Home/landing, no active activity, recording or dialog, and confirmed cloud sync; offline or conflicting work is retained. App caches contain public application code only.

Before every publication, run `node scripts/prepare-release.cjs` (or supply a YYYY-MM-DD.number version), run the tests, and commit the generated release manifest with the changed files in one commit. The Track repository keeps only its existing PAT Base entry-page/worker compatibility route pointing to canonical PAT assets; unrelated Track pages are unchanged.

## Family and provider resources

- `pat-welcome.html`: concise paper device note.
- `parent-guide.html`: sectioned family guide, including updating at home/school and Teams/Meet/Zoom preparation.
- `provider-pack.html` and `provider-invitation.txt`: reusable parent-sent onboarding, calendar format, hosted resources and coin integration.
- `clinician-guide.html`: generic setup and handover guide, linked in clinician Family setup.

B styling is the default for this release, with four alternative palettes. Main navigation and Whiz Kids identity stay fixed; parents can replace resource links, labels, activity icons and the in-app start character. Device shortcut artwork remains shared.
