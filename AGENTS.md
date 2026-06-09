# Knowledge Base — Ditelo sui Tetti iOS App

## Project Identity

This project is the native iOS app for **Ditelo sui Tetti**.

The app must feel:
- civic
- editorial
- trustworthy
- modern
- elegant
- fast
- accessible
- native Apple-first

The visual direction must follow **iOS 26 / Liquid Glass** principles:
- content first
- lightweight translucent surfaces
- layered depth
- rounded floating controls
- clear hierarchy between content and chrome
- high legibility over decoration
- restrained use of glass effects
- accessibility always more important than visual spectacle

Use Liquid Glass as a living material, not as a gimmick.

## Required Agent Skills

Before working on this repo, the agent must use the project skills installed from:

```bash
npx skills add https://github.com/Dimillian/Skills.git
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
```

The agent must prefer these skills for:
- SwiftUI architecture
- reusable component design
- modern navigation
- async/await networking
- state management
- iOS best practices
- Apple Human Interface Guidelines alignment
- previews and testability
- clean refactors

If there is a conflict between generic code suggestions and the SwiftUI/iOS skills, follow the SwiftUI/iOS skills.

## Core Technical Rules

Use:
- Swift
- SwiftUI
- async/await
- URLSession for the first sync layer
- Codable DTOs
- Observable state containers
- reusable views
- modular file organization

Do not use:
- UIKit unless strictly necessary
- forced unwraps
- massive views
- business logic inside views
- hardcoded secrets
- global mutable state
- duplicated UI components
- unnecessary third-party dependencies

Prefer:
- small composable views
- clear model boundaries
- explicit loading/error/empty states
- deterministic previews
- accessibility labels
- dynamic type support
- dark mode support
- reusable design tokens

## Backend Contract

The backend is already live.

Full sync endpoint:

```
https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial
```

Delta sync endpoint:

```
https://kbswgeliohnpwopzzzpc.supabase.co/functions/v1/sync-editorial?since=2026-05-19T00:00:00Z
```

The endpoint is public. No authentication is required for the first version.

## Liquid Glass Rules

Use Liquid Glass-inspired surfaces carefully.

Prefer:
- `.ultraThinMaterial`
- `.thinMaterial`
- translucent cards
- floating tab bars
- layered surfaces
- rounded corners
- subtle shadows
- restrained blur

Do not:
- reduce readability
- put long text on transparent glass
- overuse blur
- create low-contrast text

Main article text should be on solid or near-solid backgrounds.

## Accessibility Rules

Every screen must support:
- Dynamic Type
- VoiceOver labels
- sufficient contrast
- tappable areas at least 44×44
- reduced motion tolerance
- readable layout on small iPhones

## Definition of Done

A task is complete only when:
- app builds
- no obvious runtime crash
- previews still work where relevant
- loading state exists
- error state exists
- empty state exists
- components remain reusable
- no secrets are hardcoded
