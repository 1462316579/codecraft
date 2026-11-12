## How it works

1. Each row is one prompt fragment: the leading number sets its order in the system prompt, and the badge on the right shows which layer this copy comes from.
2. Only one copy per number takes effect, with priority Project > Global > Local > Built-in.
3. Tap a row to preview its content and edit it from the detail page; swipe left to delete the override in the writable layer, which then falls back to the next layer.
4. The + button in the top bar adds a fragment with a free number; multi-select batch-deletes custom fragments; reset clears all custom fragments in the project and global layers.
5. The "disable built-in prompts" switch keeps only your custom fragments — you must then provide every rule yourself, so enable it with care.
6. The "scenario prompts" section lists the three built-in project-type prompts (coding / writing / app reverse engineering) injected by project kind. They are read-only; to override, place a file with the same name under `prompts.custom/scenarios/`.
7. Changes take effect immediately — no app restart needed.
