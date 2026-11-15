# PAT @ Whiz Kids

Portable Access to Therapy: the shared My Base application for authorised families and therapy teams.

[Open My Base](https://whizkidal.github.io/PAT-WhizKids/portable-practice.html)

## Repository boundary

This repository contains reusable application code, generic icons, database schema and tests only. Participant configurations, personalised images, recordings and records belong in the dedicated PAT Supabase project, protected by sign-in and row-level access rules. Formal clinical documents belong in SharePoint / Halaxy. Never commit participant backups or credentials.

The same application supports each participant's private configuration and the generic template. The therapy gateway opens Speech, OT, PBS and School; participant-specific branding and interests are loaded privately.

## Setup and checks

See [the setup guide](PORTABLE_PRACTICE_README.md). Run npm ci followed by npm test. Publish the main branch root with GitHub Pages. Add the published page to the PAT project's authentication redirect allowlist before moving sign-in links.

## Reward policy and help messages — 15 November 2026

Apply `supabase/reward_policy.sql` after the existing foundation, hub, tablet and PIN schemas. The shared client caps ordinary practice coins at agreed weekly targets, has one completion bonus and one additional-work bonus from Sunday, and requires authenticated parent/clinician approval. The database guard protects clinician-owned targets and assignments, rejects child-account approvals, repeated sessions, invalid coin values and over-cap awards. A Family PIN is an additional interface check, not the server authentication boundary. Ordinary practice, including Speech, follows the current activity instructions and usually 10–15 minutes; approval requires at least ten observed engaged minutes. New clinician-assigned tasks use their explicit finish criteria. Routines remain separate.

Run `node tests/reward-policy.test.cjs` as well as the existing cloud, install and help-handler checks. Do not test by leaving fictional activity records in a participant workspace. Legacy earned coins remain intact.

Apply `supabase/help_message.sql` before deploying the updated `pat-help` function. The optional message is at most 500 characters, is bound to the request identity for retries, and is sent only to the server-configured parent. No raw dictation audio is emailed. The function validates the bearer token itself, as before. Browser dictation support varies and may use a remote browser speech service; keyboard dictation and typing remain alternatives.

Story Safari is maintained separately in Therapy-Games. Its optional familiar-voice clips stay in that browser's IndexedDB, with explicit export/import; they are not automatically part of PAT cloud audio.

## Migration from Track

PAT was extracted from WhizkidAl/Track-WhizKids at commit 043f82f0ad83ab982c665c4900402a68225093d9 on 14 November 2026. Track remains a separate application and repository. The old PAT address remains available for existing tablet shortcuts during migration. The database, accounts and participant records are unchanged. Check Saved to cloud before replacing a tablet shortcut.

The complete parent guide is available inside Family setup and in `parent-guide.html`. Parents can edit Explore/Make labels, emojis, HTTPS links, visibility and custom choices, plus preset colour themes and card text size. Personalisation does not change reward targets. Team invitation drafts are parent-authored.

## Installed-app updates

The installed app checks for a newer release on resume, online recovery, return to Home and once per minute while visible. It validates released asset hashes before reloading. Updates wait for Home/landing, no active activity, recording or dialog, and confirmed cloud sync; offline or conflicting work is retained. App caches contain public application code only.

Before every publication, run `node scripts/prepare-release.cjs` (or supply a YYYY-MM-DD.number version), run the tests, and commit the generated release manifest with the changed files in one commit. The Track repository keeps only its existing My Base entry-page/worker compatibility route pointing to canonical PAT assets; unrelated Track pages are unchanged.
