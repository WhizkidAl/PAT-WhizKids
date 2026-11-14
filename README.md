# PAT @ Whiz Kids

Portable Access to Therapy: the shared My Base application for authorised families and therapy teams.

[Open My Base](https://whizkidal.github.io/PAT-WhizKids/portable-practice.html)

## Repository boundary

This repository contains reusable application code, generic icons, database schema and tests only. Participant configurations, personalised images, recordings and records belong in the dedicated PAT Supabase project, protected by sign-in and row-level access rules. Formal clinical documents belong in SharePoint / Halaxy. Never commit participant backups or credentials.

The same application supports each participant's private configuration and the generic template. The therapy gateway opens Speech, OT, PBS and School; participant-specific branding and interests are loaded privately.

## Setup and checks

See [the setup guide](PORTABLE_PRACTICE_README.md). Run npm ci followed by npm test. Publish the main branch root with GitHub Pages. Add the published page to the PAT project's authentication redirect allowlist before moving sign-in links.

## Migration from Track

PAT was extracted from WhizkidAl/Track-WhizKids at commit 043f82f0ad83ab982c665c4900402a68225093d9 on 14 November 2026. Track remains a separate application and repository. The old PAT address remains available for existing tablet shortcuts during migration. The database, accounts and participant records are unchanged. Check Saved to cloud before replacing a tablet shortcut.
