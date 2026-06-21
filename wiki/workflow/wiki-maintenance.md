---
id: wiki-maintenance
title: Wiki Maintenance
status: active
layer: workflow
depends_on: [concept-to-implementation]
last_reviewed: 2026-06-21
---

# Wiki maintenance

## When to update

| Event | Action |
|---|---|
| New game concept | New `F###` RFC + `manifest.yaml` entry |
| Design lock changed | Update `locked-decisions.md` + `last_reviewed` |
| Feature shipped | `status: implemented`, fill `implements:` |
| Physics invariant changed | Update `wiki/invariants/*` + run `make check` |
| Architecture decision | New or updated page under `architecture/` |
| Contradiction found | Wiki wins after update in same PR |

## Required frontmatter fields

Every wiki page except `README.md` and `features/_template.md`:

- `id`, `title`, `status`, `layer`, `depends_on`, `last_reviewed`

Feature pages also require: `acceptance`, `implements`, `blocks` (may be empty).

## Validation

```bash
sh scripts/check_wiki.sh   # W1–W8
make check                 # includes wiki checks
```

## Do not duplicate

Invariant prose lives **only** in `wiki/invariants/`. [`.cursor/rules/`](../../.cursor/rules/13-wiki-governance.mdc)
are thin pointers. Root docs link here; they do not copy specs.
