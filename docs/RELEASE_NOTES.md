# Release Notes — Ditelo sui Tetti iOS

Most recent first.

---

## 1.0.2 (build 2) — 2026-06-17

### App Store "What's New" (IT)

In questa versione abbiamo migliorato l'affidabilità dei contenuti e aggiunto il supporto:

- Sincronizzazione editoriale più affidabile: i nuovi articoli, eventi e documenti compaiono sempre e restano aggiornati.
- I link di condivisione ora usano il dominio ufficiale suitetti.org.
- Nuova sezione "Supporto tecnico" in "Chi siamo" per contattare il team via email.
- Schede PDF più curate e immagine ufficiale al posto dei contenuti senza copertina.
- Notifica di aggiornamento app quando è disponibile una nuova versione.
- Correzioni e ottimizzazioni varie.

### Technical summary

| Area | Change |
|------|--------|
| Editorial sync | Fetch always from origin (`.reloadIgnoringLocalCacheData`); signature-gated cache replacement; foreground-resume refresh when stale. |
| Article/event/document updates | Resilient DTO decoding (only `id`+`titolo` required) — articles with a null field (e.g. `estratto`) are no longer dropped; full cache reconciliation against the sync payload + recovery net. |
| Sharing | Canonical `https://www.suitetti.org/{articoli\|eventi\|documenti}/{slug}` URLs with inviting share text + App Store link. |
| Support | "Supporto tecnico" card → `mailto:info@digitalyogin.com`, subject stamped with app version/build. |
| UI | Premium PDF cards; official brand-logo fallback for imageless content; Home festival CTA disabled (kept for future banner reuse). |
| Update system | Remote-config `app-config` endpoint drives soft/forced in-app update prompts. |
| Android (docs only) | Push-notification infrastructure documented for the Android port — **no change to iOS APNs**. |
| Backend | Stale-content synchronization mitigated server-side — no iOS change required. |

Build: `** BUILD SUCCEEDED **` (Debug, iPhone 17 Pro simulator).

---

## 1.0.1 / 1.0 — earlier

See `CHANGELOG_AI.md` for the full AI-assisted change history (RC core, attachments, sorting, document URL audit, etc.).
