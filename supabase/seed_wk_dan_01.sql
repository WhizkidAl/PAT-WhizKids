-- NOT APPLIED. Review with the clinician before running.
-- PAT project only (ifrzwfklznutsxgtkivr). Do not run this on Track.
-- Does not create auth users, send email, or invite anyone.
-- Placeholder participant code WK-DAN-01. No real names or email addresses.
--
-- Coin rules are unchanged. One approved finished burst can earn one coin, up to the
-- weekly target below. 2 bursts a day for Monday–Sunday is 14. Edit v_weekly_coin_target
-- and the same number in the configuration JSON before running if the cap should be
-- lower (for example 10 for weekdays only, or 2). The script writes the variable into
-- the hub after reading the JSON.
-- bursts_per_day on the game row is the practice dose the parent check-in compares with.
-- It is not a second coin rule.
--
-- Re-running is safe only while this code has no hub snapshot yet. After the family
-- has saved records, do not re-run this script.

do $seed$
declare
 pid uuid;
 cfg jsonb;
 game jsonb;
 existing_snapshot jsonb;
 v_weekly_coin_target integer := 14;
begin
 if v_weekly_coin_target < 1 or v_weekly_coin_target > 20 then
  raise exception 'Weekly coin target must stay inside the existing 1–20 frequency range';
 end if;
 if (select count(*) from public.participants where display_name='WK-DAN-01') > 1 then
  raise exception 'More than one WK-DAN-01 participant. Stop.';
 end if;
 select id into pid from public.participants where display_name='WK-DAN-01';
 if pid is null then
  insert into public.participants(display_name) values('WK-DAN-01') returning id into pid;
 end if;

 -- seed-configuration
 cfg := $cfg${
  "participantLabel": "WK-DAN-01",
  "backupKind": "pat-base",
  "feedbackEmail": "",
  "planRevision": 1,
  "scheduleRevision": 1,
  "pictureRevision": 1,
  "collectionRevision": 1,
  "providerLinkRevision": 1,
  "defaultAvatar": "icons/my-base-snake-512.png",
  "startImage": "icons/my-base-snake-512.png",
  "applicationAssets": {
    "snakeRest": "icons/my-base-snake-512.png",
    "snakeAwake": "icons/my-base-snake-512.png"
  },
  "approval": {"pin": "", "salt": ""},
  "practice": {"minutes": 15, "eveningTime": "19:30"},
  "extras": [],
  "offlineTasks": [],
  "cards": [],
  "patHidden": [],
  "links": {
    "speech": "", "ot": "", "pbs": "", "school": "", "worker": "",
    "resources": "", "parentInstructions": "", "providerGuide": "", "onlineTools": "",
    "toolFeedback": "", "reportIssue": "", "widerSystem": "",
    "day": "", "week": "", "nessy": "", "numbers": "", "zoo": "",
    "creations": "", "create": "", "gemini": "", "youtube": "", "tasks": "", "book": ""
  },
  "routines": {
    "morning": [{"icon": "⭐", "name": "Get ready"}],
    "afternoon": [{"icon": "⭐", "name": "Choose one practice"}]
  },
  "targets": {"all-aboard": 14},
  "assignments": [{
    "id": "all-aboard",
    "title": "All Aboard!",
    "discipline": "speech",
    "emoji": "🚂",
    "url": "",
    "location": "All Aboard in Speech",
    "finish": "Finish one All Aboard round (one burst). Leaving early is recorded as stopped.",
    "frequency": 14
  }]
 }$cfg$::jsonb;
 cfg := jsonb_set(cfg, '{participantId}', to_jsonb(pid::text));
 cfg := jsonb_set(cfg, '{targets,all-aboard}', to_jsonb(v_weekly_coin_target));
 cfg := jsonb_set(cfg, '{assignments,0,frequency}', to_jsonb(v_weekly_coin_target));

 select snapshot into existing_snapshot from public.pat_hubs where participant_id=pid;
 if not found then
  insert into public.pat_hubs(participant_id, configuration, snapshot, audio)
  values(pid, cfg, null, '{}'::jsonb);
 elsif existing_snapshot is null then
  update public.pat_hubs set configuration=cfg where participant_id=pid;
 else
  raise notice 'WK-DAN-01 already has a snapshot. Configuration and records were left unchanged.';
 end if;

 -- seed-game-config
 game := $game${
  "id": "wk-dan-01-all-aboard",
  "title": "All Aboard!",
  "version": "1.0.0",
  "theme": {
    "name": "red-trains",
    "trainColour": "#9f1d1d",
    "carriageColour": "#f8d7cf",
    "background": "#f4efe6",
    "ink": "#1b2430",
    "accent": "#0e6b4c",
    "card": "#fffdf8",
    "focus": "#0b57d0"
  },
  "roundMinutes": 4,
  "resultsOrigin": "https://whizkidal.github.io",
  "players": {"childLabel": "Player 1", "opponentLabel": "Station guard", "opponent": "computer"},
  "defaultLevel": "1",
  "wildCards": {"tunnel": true, "disco": true, "red-signal": true, "swap-track": true},
  "music": false,
  "maxMixUps": 1,
  "repairCheck": "I heard {heard}. Do you mean {heard} or {intended}?",
  "repairStrategies": [
    {"id": "key-word", "label": "Say the key word", "emoji": "🗣️", "image": "", "picture": "key-word", "kind": "speech", "hint": "Say the word you meant."},
    {"id": "show-or-point", "label": "Show or point", "emoji": "👉", "image": "", "picture": "show-or-point", "kind": "show", "hint": "Point to the card or hold it up."},
    {"id": "another-way", "label": "Tell it another way", "emoji": "💬", "image": "", "picture": "another-way", "kind": "meaning", "hint": "Use another word or a short clue."}
  ],
  "sets": [
    {
      "id": "bell-set",
      "name": "Bell train",
      "approach": "multiple-oppositions",
      "contrast": "onset",
      "words": [
        {"id": "bell", "text": "bell", "emoji": "🔔", "image": "", "nonword": false, "role": "engine"},
        {"id": "fell", "text": "fell", "emoji": "🍂", "image": "", "nonword": false, "role": "carriage"},
        {"id": "spell", "text": "spell", "emoji": "✨", "image": "", "nonword": false, "role": "carriage"},
        {"id": "smell", "text": "smell", "emoji": "👃", "image": "", "nonword": false, "role": "carriage"}
      ]
    },
    {
      "id": "bill-set",
      "name": "Bill train",
      "approach": "multiple-oppositions",
      "contrast": "onset",
      "words": [
        {"id": "bill", "text": "bill", "emoji": "💵", "image": "", "nonword": false, "role": "engine"},
        {"id": "fill", "text": "fill", "emoji": "🪣", "image": "", "nonword": false, "role": "carriage"},
        {"id": "spill", "text": "spill", "emoji": "💧", "image": "", "nonword": false, "role": "carriage"},
        {"id": "smill", "text": "smill", "emoji": "🌟", "image": "", "nonword": true, "role": "carriage"}
      ]
    },
    {
      "id": "bin-set",
      "name": "Bin train",
      "approach": "multiple-oppositions",
      "contrast": "onset",
      "words": [
        {"id": "bin", "text": "bin", "emoji": "🗑️", "image": "", "nonword": false, "role": "engine"},
        {"id": "fin", "text": "fin", "emoji": "🐟", "image": "", "nonword": false, "role": "carriage"},
        {"id": "spin", "text": "spin", "emoji": "🌀", "image": "", "nonword": false, "role": "carriage"},
        {"id": "smin", "text": "smin", "emoji": "⭐", "image": "", "nonword": true, "role": "carriage"}
      ]
    }
  ]
 }$game$::jsonb;

 if existing_snapshot is null then
  insert into public.pat_assigned_games(participant_id, catalogue_id, enabled, bursts_per_day, config)
  values(pid, 'all-aboard', true, 2, game)
  on conflict(participant_id, catalogue_id) do update
  set enabled=true, bursts_per_day=excluded.bursts_per_day, config=excluded.config;
 end if;
end
$seed$;
