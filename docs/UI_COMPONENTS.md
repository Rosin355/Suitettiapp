# UI Components & Design System — Ditelo sui Tetti

> Living document for the Android / Jetpack Compose conversion. It mirrors the verified iOS SwiftUI design system and the reusable component catalog so the Compose build reaches visual + behavioral parity. Source of truth: the iOS codebase (`DiteloSuiTetti/Design/*` and `DiteloSuiTetti/Components/*`). Update this file whenever a token or component changes.

---

## 1. Design Language

The app must feel **civic, editorial, trustworthy, modern, elegant, fast, accessible, native-first**. The visual direction follows **iOS 26 / Liquid Glass** principles, which translate to Material 3 + custom translucency on Android:

- Content first; chrome is lightweight and translucent.
- Layered depth via soft shadows and 0.5pt hairline borders.
- Rounded floating controls and a floating tab bar.
- Clear hierarchy between content and chrome.
- High legibility over decoration; **main article body text always sits on solid/near-solid surfaces**, never on transparent glass.
- Restrained blur and translucency. Accessibility always outranks visual spectacle.

Liquid Glass is a living material, not a gimmick.

---

## 2. Design Tokens

All numeric tokens live in `DiteloSuiTetti/Design/AppSpacing.swift` (the `DT` enum); colors in `AppColors.swift`. Values below are the **verified** ones from source.

### 2.1 Colors

| Token | SwiftUI name | RGB (0–255) | Hex | Role | Compose equivalent |
|---|---|---|---|---|---|
| Background cream | `brandCream` | 242, 239, 233 | `#F2EFE9` | App / screen background, PDF page backing, image fallback backing | `BrandCream` |
| Accent red | `brandRed` | 232, 25, 44 | `#E8192C` | Accent, tint, PDF affordances, CTAs, category color default | `BrandRed` |
| Text | `brandBlack` | 26, 26, 26 | `#1A1A1A` | Primary text / titles | `BrandBlack` |
| Metadata | `brandGray` | 94, 94, 94 | `#5E5E5E` | Secondary text, metadata, descriptions | `BrandGray` |
| Faint metadata | `brandGrayLight` | 160, 160, 160 | `#A0A0A0` | Tertiary text, disabled states, dot separators | `BrandGrayLight` |
| Separator | `brandSep` | black @ 8% | `#000000` α0.08 | Dividers / hairlines | `BrandSep` |
| Yellow | `brandYellow` | 245, 232, 74 | `#F5E84A` | Accent highlight (sparingly) | `BrandYellow` |
| Yellow light | `brandYellowLight` | 252, 239, 170 | `#FCEFAA` | Soft highlight backing | `BrandYellowLight` |

> Note: the fact-sheet quoted `~#C0141E`/`~#F5EFE6`; the source files compile the exact values above. Use the exact values.

**Tints / fills used repeatedly:**
- Category chip background: `categoryColor.opacity(0.13)` (list) / `0.14` (default chip).
- PDF icon tile fill: `brandRed.opacity(0.12)`; document row tile: `brandRed.opacity(0.12)`; event info icon tile: `brandRed.opacity(0.10)`.
- "Apri PDF" action strip background: `brandRed.opacity(0.08)`.
- Disabled / unavailable backings: `black.opacity(0.04)`–`0.06`.

### 2.2 Shape, spacing & layout

| Token | Value | Use |
|---|---|---|
| `cornerRadius` | **22** | Cards, list containers, large surfaces |
| `smallCorner` | **14** | Thumbnails, icon tiles, inner tiles |
| `padding` | **16** | Standard content / horizontal screen padding |
| `sectionSpacing` | **12** | Vertical gap between stacked cards/sections |
| `topBarContentOffset` | **62** | Hero text offset below the floating top bar |
| `readableMaxWidth` | **820** | Max readable content column width on iPad / wide screens |

Other recurring metrics: inner card padding `16`; row vertical padding `13`; row HStack spacing `14`; small inter-element spacing `5–8`.

### 2.3 Surfaces (Liquid Glass)

| Surface | iOS recipe | Compose equivalent |
|---|---|---|
| Translucent card / list container | `.background(.white.opacity(0.82))` + `clipShape(rect(cornerRadius: 22))` + `strokeBorder(.white.opacity(0.8), 0.5)` + soft shadow | `Color.White.copy(alpha = 0.82f)` over the cream background, `RoundedCornerShape(22.dp)`, `border(0.5.dp, Color.White.copy(alpha=0.8f))`, `shadow(...)` |
| Solid card (PDF, detail body) | `.background(.white)` + 22 corner + `strokeBorder(.black.opacity(0.06), 0.5)` + shadow | `Color.White` surface, same shape/border |
| System material | `.ultraThinMaterial` / `.thinMaterial` (tab bar, chrome) | `Modifier.blur` / `HazeBlur`-style translucency, or Material 3 elevated surface with low alpha — keep restrained |
| Card shadow (default) | `shadow(black 0.06, r8, y2)` + `shadow(black 0.04, r1, y0.5)` (`.cardShadow()`) | `Modifier.shadow(elevation = 8.dp, ...)` tuned to match |
| Featured / PDF shadow | `shadow(black 0.07, r8–10, y2–3)` | matching `elevation` |

> On Android, true backdrop blur is expensive pre-API 31. Prefer a flat `white @ 0.82` over the cream background for parity; reserve real blur (`RenderEffect.createBlurEffect`) for API 31+ chrome only.

### 2.4 Typography

iOS uses **large editorial system fonts** with bold/black weights, **negative kerning** on titles, and **italic Georgia** accents (`Font.georgia(_:)` / `Font.georgiaItalic(_:)` in `AppTypography.swift`). Dynamic Type is supported throughout.

| Role | iOS size / weight | Kerning | Compose (sp) |
|---|---|---|---|
| Row / featured title | 14, semibold/bold | `-0.25` to `-0.3` | `14.sp`, `FontWeight.SemiBold/Bold`, `letterSpacing = (-0.25).sp` |
| PDF card title | 16, semibold | — | `16.sp` SemiBold |
| Event info primary line | 15, semibold | — | `15.sp` SemiBold |
| Section / metadata caption | 10–12 | `+0.3` to `+0.5` (uppercase labels) | `10–12.sp`, positive `letterSpacing` |
| Chip / pill | 11, semibold/bold | `+0.3` / `+0.5` | `11.sp` |
| Empty-state title | 17, semibold | — | `17.sp` |
| Editorial italic accent | Georgia italic | — | a serif (e.g. bundled Georgia-like) italic |

**Compose mapping rule:** iOS points → Compose `sp` 1:1, and Dynamic Type → `LocalDensity.fontScale` / system `FontScale`. Use `sp` (not `dp`) for all text so Android font-size accessibility settings scale it.

---

## 3. Component Catalog

Each entry lists the iOS file, the key visual spec (verified), and the Compose equivalent. Components are pure/presentational — business logic stays in the stores.

### 3.1 CategoryChip (pill)
**File:** `Components/Chips/CategoryChip.swift`

- Text 11pt semibold, kerning `+0.3`, foreground = category color (default `brandRed`).
- Padding H `11`, V `4`; background `color.opacity(0.14)` (caller may override, list uses `0.13`); `Capsule()` shape.

**Compose:** small `Surface`/`Box` with `RoundedCornerShape(50)` (full pill), `tint.copy(alpha=0.14f)` background, `Text(11.sp, SemiBold, letterSpacing=0.3.sp, color=tint)`, content padding `(11.dp, 4.dp)`.

### 3.2 ArticleListRow
**File:** `Components/Rows/ArticleListRow.swift`

- HStack spacing `14`, padding H `16` / V `13`.
- Leading thumbnail: `RemoteImageView` `58×58`, `cornerRadius 14`, soft shadow.
- Content: `CategoryChip` → title (14 semibold, 2 lines, kerning `-0.25`) → metadata row (`fullDate` • `readTime`, 12pt, `brandGray`, 2.5pt dot separator).
- Trailing chevron `chevron.right` 11pt.
- Bottom `Divider().padding(.leading, 88)` unless `isLast`.
- **A11y:** `.combine`, label = `"{category}. {title}. {fullDate}, {readTime} di lettura."`

**Compose:** `Row` with `Image`(58.dp, 14.dp corners) + `Column { CategoryChip; Text(title, maxLines=2); Row(metadata) }` + trailing chevron `Icon`. `HorizontalDivider(Modifier.padding(start=88.dp))`. `Modifier.semantics(mergeDescendants=true){ contentDescription = "…" }`, `clickable` row ≥ 48.dp tall.

### 3.3 FeaturedArticleCard
**File:** `Components/Cards/FeaturedArticleCard.swift`

- Fixed width `196`; translucent surface `white @ 0.82`, corner `22`, hairline `white @ 0.8` 0.5pt, shadow `black 0.07 / r8 / y2`.
- Top: `RemoteImageView` height `108`, clipped, with a bottom `LinearGradient(clear → black 0.35)` (height 54) so the overlaid `CategoryChip` (padding 10) stays legible.
- Body: title (14 bold, 2 lines, kerning `-0.3`) + metadata (`date` • `readTime`, 12pt `brandGrayLight`). Body padding H `13`, top `11`, bottom `14`.

**Compose:** fixed `width(196.dp)` `Card`/`Box`; `Box { CoilImage(height=108.dp, ContentScale.Crop); gradient scrim; CategoryChip(align=BottomStart, padding 10.dp) }` then `Column` for title/meta. Used in horizontally scrolling "In evidenza" rail (`Home`) and `Articoli` featured rail.

> The fact-sheet also names `ArticlesFeaturedCard` — treat it as the Articoli-screen variant of the featured hero card; mirror with the same Compose composable parameterized by size.

### 3.4 LinkedDocumentCard — premium PDF card (NEW)
**File:** `Components/Documents/LinkedDocumentCard.swift`
**Model:** `RelatedDocument { id: UUID, title: String, type: String, description: String, url: URL? }` (maps to backend `AttachmentDTO`). Attachments carry **no date and no file size** — do not render those.

This is the flagship reusable PDF affordance, shown in article "Documenti allegati" and event "Documenti dell'evento" lists.

**Available state (`url != nil`):**
- Solid `white` surface, corner `22`, hairline `black @ 0.06` 0.5pt, shadow `black 0.07 / r10 / y3`.
- Main row, top-aligned, spacing `14`, padding `16`:
  - **52×52 tinted icon tile**: `RoundedRectangle(cornerRadius 14)` filled `brandRed @ 0.12`, centered SF symbol `doc.richtext.fill` 24pt semibold `brandRed`.
  - **Text column:** **PDF pill** (11 bold, kerning 0.5, `brandRed`, padding H8/V3, `brandRed @ 0.12` Capsule — shows backend type uppercased if not "PDF") → **title** 16 semibold `brandBlack`, **up to 3 lines** → **optional description** 13pt `brandGray`, up to 2 lines (only if non-empty).
  - **Right open icon:** `arrow.down.circle.fill` 24pt `brandRed`.
- **Soft-red "Apri PDF" action strip** at the bottom, full width, `minHeight: 46` (≥44pt tap target via whole card), background `brandRed @ 0.08`, `brandRed` foreground: leading `arrow.up.right.square.fill` + "Apri PDF" (14 semibold) + trailing `chevron.right`.
- Tap → `PDFReaderView(remoteURL:title:)` (needs NavigationStack ancestor). Press feedback via `PressableCardStyle` (scale 0.98, respects Reduce Motion).
- **A11y:** `.accessibilityElement(children: .ignore)`, label **`"Apri documento PDF, {title}"`**, hint `"Apre il lettore PDF"`, trait `.isButton`.

**Unavailable state (`url == nil`):**
- Icon `doc.slash.fill` on `black @ 0.06` tile, grayed text, bottom strip "PDF non disponibile" (`exclamationmark.triangle`, `brandGrayLight`, `black @ 0.04`, `minHeight 42`), whole card `opacity 0.7`.
- **A11y:** label `"Documento PDF non disponibile, {title}"` (not a button).

**Compose:** `Column` card (solid white, `RoundedCornerShape(22.dp)`, hairline border, shadow). Header `Row(verticalAlignment=Top, spacing 14.dp)`: `Box(52.dp, RoundedCornerShape(14.dp), BrandRed.copy(alpha=0.12f)) { Icon(Filled.PictureAsPdf or doc icon, 24.dp, BrandRed) }`; `Column(weight=1f){ PdfPill(); Text(title, maxLines=3); description?.let{ Text(it, maxLines=2) } }`; trailing `Icon(download, 24.dp)`. Then a clickable `Row(Modifier.fillMaxWidth().heightIn(min=48.dp).background(BrandRed.copy(alpha=0.08f)))` "Apri PDF" strip. Disabled variant grays out + `alpha(0.7f)`. `Modifier.clearAndSetSemantics { contentDescription = "Apri documento PDF, $title"; role = Role.Button }`. Tap → navigate to PDF reader route with the resolved URL.

### 3.5 DocumentListRow
**File:** `Components/Rows/DocumentListRow.swift`

- HStack top-aligned, spacing `14`, padding H `16` / V `13`.
- Leading `48×48` tile `cornerRadius 12`, `brandRed @ 0.12`, `doc.fill` 20pt `brandRed`.
- Title 14 semibold (2 lines, kerning `-0.25`); metadata row: optional `type` (12 medium `brandRed`) • 2.5pt dot • `uploadedAt` (12pt `brandGrayLight`).
- Trailing chevron; `Divider().padding(.leading, 78)` unless `isLast`.
- **A11y:** `.combine`, label `"{title}, {type}, {uploadedAt}"`, hint `"Mostra dettagli documento"`.
- Drives `Documenti` list → `DocumentDetailView`.

**Compose:** `Row` with leading `Box(48.dp, 12.dp)` icon tile, content `Column`, trailing chevron, `HorizontalDivider(start=78.dp)`. Same semantics merge.

### 3.6 EventInfoCard
**File:** `Components/Events/EventInfoCard.swift`

- Single info row (e.g. Quando / Dove). HStack spacing `14`, padding H `16` / V `14`.
- Leading `40×40` tile `cornerRadius 10`, `brandRed @ 0.10`, SF symbol 15pt semibold `brandRed`.
- Column: uppercase `heading` (10 semibold `brandGray`, kerning 0.5) → `primaryLine` (15 semibold `brandBlack`) → optional `secondaryLine` (13pt `brandGray`).
- If `action != nil`: trailing `arrow.up.right` 11pt `brandGrayLight`; whole row tappable (`contentShape(Rectangle)`), used for the Maps tap on the location.

**Compose:** `Row` with 40.dp icon tile (`RoundedCornerShape(10.dp)`), text column, optional trailing arrow; `Modifier.clickable(enabled = action != null)` opening Maps intent. Keep tap target ≥ 48.dp.

### 3.7 DetailHeroImage
**File:** `Components/Detail/DetailHeroImage.swift`

- Full-width hero, default `height: 340`, `clipped`.
- `RemoteImageView` fill + bottom `LinearGradient(clear → black 0.35)` covering bottom `40%` of height for title legibility.
- A11y: hidden when no `accessibilityLabel`, else exposes the label. Used in Article detail and Event detail.

**Compose:** `Box(Modifier.fillMaxWidth().height(340.dp).clipToBounds()) { CoilImage(ContentScale.Crop); Box(gradient scrim, align=Bottom, height=40%) }`. Pass `contentDescription` or `clearAndSetSemantics{}` when decorative.

### 3.8 RemoteImageView (Coil + brand-logo fallback)
**File:** `Components/Common/RemoteImageView.swift`; cache: `Utilities/ImageCache.swift`

- Loads via the two-tier `ImageCache` (NSCache memory 100/50MB + FileManager disk).
- Phases: `idle → loading → loaded / failed`. Loading placeholder = cream + small `ProgressView` tinted `brandRed @ 0.5`.
- **Fallback (url nil OR download failure):** official brand logo asset **`dst_fallback_logo`** (`Assets.xcassets`, cream-background "DITELO SUI TETTI" skyline+wordmark), `scaledToFit` on a `brandCream` backing so the full mark shows at any aspect ratio (1:1 thumbs, wide heroes) with no seam. **Never a random gradient for editorial content** (`fallbackColors` param is legacy/unused for rendering).
- Diagnostics: `"[RemoteImageView] using fallback image — url nil (title: …)"` and `"[ImageCache] failed — fallback shown (…)"`.

**Compose:** Coil `AsyncImage` / `SubcomposeAsyncImage` with `ImageLoader` configured for memory + disk cache (Coil `DiskCache`). `error` and `fallback` painters = the same brand-logo drawable on a cream `Box`, `ContentScale.Fit`. `loading` slot = cream + `CircularProgressIndicator(BrandRed.copy(alpha=0.5f))`. Mark `contentDescription = null` (decorative; the row owns the label). Mirror diagnostics with `Log` tags.

### 3.9 EmptyStateView
**File:** `Components/Common/EmptyStateView.swift`

- Centered `VStack(spacing 20)`, fills available space, padding V `64` / H `40`.
- Icon badge: `88×88` Circle `iconTint @ 0.10`, SF symbol 34pt medium `iconTint @ 0.75` (default `brandRed`).
- Title 17 semibold `brandBlack`; subtitle 15pt `brandGray`, centered, lineSpacing 3.
- Optional primary button (`.borderedProminent`, tint `brandRed`) and/or secondary text button (`brandRed`).
- Covers **empty** and **error** states (e.g. "Nessun documento", "Connessione non disponibile" with Riprova). Each list screen must show loading + empty + error states.

**Compose:** centered `Column`; `Box(88.dp Circle, iconTint.copy(alpha=0.10f)) { Icon(34.dp, iconTint.copy(alpha=0.75f)) }`; `Text` title/subtitle; optional `Button` (Filled, `containerColor=BrandRed`) + `TextButton`. Buttons carry `contentDescription`/label.

### 3.10 SkeletonCard / SkeletonLoadingList
**File:** `Components/Loading/SkeletonCard.swift`

- **Shimmer:** moving `LinearGradient(clear → white 0.45 → clear)` overlay, `blendMode .overlay`, 1.4s linear `repeatForever`. **Reduce Motion → static `opacity 0.5`** (no animation).
- `skeletonBlock` = rounded bar `brandGrayLight @ 0.25`.
- `SkeletonListRow` mirrors `ArticleListRow` metrics (58×58 thumb, 3 bars, divider start 88).
- `SkeletonFeaturedCard` mirrors `FeaturedArticleCard` (width 196, image 108).
- `SkeletonLoadingList(count: 5)` = translucent `white @ 0.82` container, corner 22, hairline, shadow, shimmer, padded `16`.

**Compose:** shimmer brush (e.g. `Brush.linearGradient` animated with `rememberInfiniteTransition`), gated by `LocalAccessibilityManager`/a Reduce-Motion flag → static `alpha(0.5f)` when motion is reduced. Compose placeholder bars = `RoundedCornerShape` filled `BrandGrayLight.copy(alpha=0.25f)`. Mark skeletons `clearAndSetSemantics {}` so TalkBack skips them.

### 3.11 PDF reader (PDFKitView / PDFReaderView)
**Files:** `Components/PDF/PDFKitView.swift`, `Screens/Documents/PDFReaderView.swift`; download via `Services/PDF/PDFDownloadService`.

- iOS: `PDFKitView` wraps `PDFView` — `autoScales`, `displayMode .singlePageContinuous`, vertical direction, `backgroundColor = brandCream`. `PDFDownloadService` downloads to tmp, validates MIME/extension, caches; diagnostics tags `[DocumentURL]` / `[DocumentPDF]`.
- Always uses the **resolved backend URL**. For Documents, **prefer a direct `.pdf` URL over a page URL** (`DocumentDTO` picks `.pdf` among candidate fields). Article/Event attachments and Documents all open here.
- Document detail offers **Leggi PDF / Apri esternamente / Share**.

**Compose / Android:** primary `PdfRenderer` (download-to-cache then render pages in a vertical `LazyColumn`, cream page background), with **WebView or Chrome Custom Tabs as fallback**. Mirror the download+validate+cache step (Room/DataStore + file cache) and the `.pdf`-preferred URL resolution. Provide the same three actions (open in reader / open externally / share).

> Known backend caveat: 7 of 25 documents carry legacy `www.suitetti.org` URLs that 404 or return HTML (re-host pending). The reader must degrade gracefully (show the error/empty state, offer "Apri esternamente") rather than crash.

---

## 4. Chrome: Floating Tab Bar

**File:** `ContentView.swift`

iOS 26 uses the **native `TabView` with `Tab(...)` items** — a system floating, translucent tab bar (no custom bar). Four tabs, each its own `NavigationStack`; global tint `brandRed`:

| Tab | Title | SF Symbol | Compose icon (Material) |
|---|---|---|---|
| `.home` | Home | `house.fill` | `Icons.Filled.Home` |
| `.articoli` | Articoli | `doc.text.fill` | `Icons.AutoMirrored.Filled.Article` |
| `.documenti` | Documenti | `folder.fill` | `Icons.Filled.Folder` |
| `.chiSiamo` | Chi siamo | `info.circle.fill` | `Icons.Filled.Info` |

**Compose:** `NavigationBar` (Material 3) with a translucent container over the cream background and `selectedIndicatorColor`/`indicatorColor` tuned to `BrandRed`, each destination a `NavHost`/back stack. For the floating look, give the bar rounded corners + low elevation + slight translucency. Deep links (`suitetti.org/{articoli|eventi|documenti}/{slug}`) resolve to the matching tab + detail, mirroring `AppDeepLinkRouter`.

---

## 5. Accessibility (parity rules)

| Concern | iOS | Android / Compose |
|---|---|---|
| Combined row labels | `.accessibilityElement(children: .combine)` with Italian label string | `Modifier.semantics(mergeDescendants = true){ contentDescription = "…" }` |
| PDF card label | **"Apri documento PDF, {title}"**, hint "Apre il lettore PDF", button trait | `clearAndSetSemantics { contentDescription = "Apri documento PDF, $title"; role = Role.Button }` |
| Decorative images / icons | `.accessibilityHidden(true)` | `contentDescription = null` or `clearAndSetSemantics {}` |
| Min touch target | ≥ **44×44 pt** (PDF strip uses `minHeight 46`) | ≥ **48×48 dp** (`Modifier.minimumInteractiveComponentSize()` / `sizeIn(minHeight=48.dp)`) |
| Dynamic Type | system, on by default | text in **`sp`**, honor `FontScale`; test up to largest accessibility sizes |
| Reduce Motion | shimmer + press scale guarded (`accessibilityReduceMotion`) | check system "Remove animations"; disable shimmer/scale, use static `alpha` |
| Contrast | `brandGray` for metadata; body text on solid surfaces | keep WCAG-AA contrast; never put body text on the 0.82 glass |
| Empty/error/loading | every list screen has all three states | same — provide loading skeleton, empty state, error state |

---

## 6. iPad / Tablet Adaptation

- **Readable-width constraint:** on `horizontalSizeClass == .regular` (iPad), list and detail content is centered and capped at **`readableMaxWidth = 820`pt**.
- **Articoli split:** iPad uses a `GeometryReader` `HStack` split — list on the left at ~40% of width **clamped to 280–400pt**, detail on the right — driven by an `onSelect` closure. iPhone uses `NavigationLink` + `.navigationTransition(.zoom)`.

**Compose:** use `WindowSizeClass`. For **Expanded/Medium** width, render a list-detail layout (`ListDetailPaneScaffold` from `androidx.compose.material3.adaptive`, or a manual `Row`) with the list pane width clamped `280.dp..400.dp`. Constrain content columns to `Modifier.widthIn(max = 820.dp).align(Alignment.CenterHorizontally)` on wide screens. **Compact** width = single-pane navigation with a shared-element/transition.

---

## 7. Compose Theme & Modifier Sketch

Reference scaffold for the Android side (not production-final — tune shadows/blur to match iOS visually).

```kotlin
// --- Tokens ---
object Brand {
    val Red        = Color(0xFFE8192C)
    val Cream      = Color(0xFFF2EFE9)
    val Black      = Color(0xFF1A1A1A)
    val Gray       = Color(0xFF5E5E5E)
    val GrayLight  = Color(0xFFA0A0A0)
    val Yellow     = Color(0xFFF5E84A)
    val YellowLight= Color(0xFFFCEFAA)
    val Sep        = Color.Black.copy(alpha = 0.08f)
}

object Dimens {
    val CornerRadius     = 22.dp
    val SmallCorner      = 14.dp
    val Padding          = 16.dp
    val SectionSpacing   = 12.dp
    val TopBarOffset     = 62.dp
    val ReadableMaxWidth = 820.dp
    val MinTouchTarget   = 48.dp
}

private val DiteloColorScheme = lightColorScheme(
    primary    = Brand.Red,
    onPrimary  = Color.White,
    background = Brand.Cream,
    onBackground = Brand.Black,
    surface    = Color.White,
    onSurface  = Brand.Black,
    outline    = Brand.Sep,
)

private val DiteloShapes = Shapes(
    small  = RoundedCornerShape(Dimens.SmallCorner),
    medium = RoundedCornerShape(Dimens.CornerRadius),
    large  = RoundedCornerShape(Dimens.CornerRadius),
)

@Composable
fun DiteloTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DiteloColorScheme,
        shapes = DiteloShapes,
        typography = DiteloTypography, // sizes in sp: titles 14–16 SemiBold/Bold, negative letterSpacing
        content = content,
    )
}

// --- Liquid Glass translucent card surface ---
fun Modifier.glassCard(corner: Dp = Dimens.CornerRadius) = this
    .shadow(8.dp, RoundedCornerShape(corner), clip = false)
    .clip(RoundedCornerShape(corner))
    .background(Color.White.copy(alpha = 0.82f))          // over Brand.Cream background
    .border(0.5.dp, Color.White.copy(alpha = 0.8f), RoundedCornerShape(corner))

// --- Solid card (PDF / detail body) ---
fun Modifier.solidCard(corner: Dp = Dimens.CornerRadius) = this
    .shadow(10.dp, RoundedCornerShape(corner), clip = false)
    .clip(RoundedCornerShape(corner))
    .background(Color.White)
    .border(0.5.dp, Color.Black.copy(alpha = 0.06f), RoundedCornerShape(corner))

// --- Readable column on wide screens ---
fun Modifier.readableWidth() = this
    .widthIn(max = Dimens.ReadableMaxWidth)

// --- CategoryChip ---
@Composable
fun CategoryChip(text: String, tint: Color = Brand.Red) {
    Box(
        Modifier
            .clip(RoundedCornerShape(50))
            .background(tint.copy(alpha = 0.14f))
            .padding(horizontal = 11.dp, vertical = 4.dp)
    ) {
        Text(
            text, color = tint,
            fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.3.sp,
        )
    }
}
```

---

## 8. Component → Compose Quick Map

| iOS component | Compose composable | Notes |
|---|---|---|
| `CategoryChip` | `CategoryChip` (Box + pill) | tint-driven |
| `ArticleListRow` | `ArticleRow` | Coil thumb + merged semantics + divider |
| `FeaturedArticleCard` / `ArticlesFeaturedCard` | `FeaturedArticleCard` | fixed 196.dp, gradient scrim |
| `LinkedDocumentCard` | `LinkedDocumentCard` | premium PDF card; "Apri PDF" strip; nav to reader |
| `DocumentListRow` | `DocumentRow` | 48.dp icon tile |
| `EventInfoCard` | `EventInfoCard` | optional Maps click |
| `DetailHeroImage` | `DetailHero` | 340.dp, bottom scrim |
| `RemoteImageView` | `RemoteImage` (Coil) | disk+memory cache, brand-logo fallback |
| `EmptyStateView` | `EmptyState` | empty + error |
| `SkeletonLoadingList` / `SkeletonCard` | `SkeletonList` | shimmer, Reduce-Motion aware |
| `PDFKitView` / `PDFReaderView` | `PdfReader` (PdfRenderer) | WebView/Custom Tabs fallback; prefer `.pdf` URL |
| `TabView` + `Tab` | `NavigationBar` + `NavHost` | floating translucent, 4 tabs, deep links |
| `PressableCardStyle` | `clickable` + scale `0.98f` | gate on Reduce Motion |
| `HomeFeaturedEventCard` | `HomeFeaturedEventCard` | backend-driven banner; render only when a featured event exists |

---

## 9. Definition of Done (per component)

A Compose component reaches parity when: it matches the token values above; supports light + (where relevant) the cream-on-white surface model; exposes the same TalkBack label/role; has ≥ 48.dp touch targets; scales text via `sp`/`FontScale`; honors Reduce Motion; and renders correct **loading / empty / error** states on its hosting screen. No hardcoded secrets, no business logic in the composable.

---

## Addendum — new/changed components (2026-06-09)

| Component | iOS | Compose equivalent |
|---|---|---|
| **Support card** (About → "Supporto tecnico") | `AboutSupportSection`: GCard with wrench icon, "Hai bisogno di aiuto?", subtitle, "Scrivi a Digital Yogin" row → `mailto:`; alert fallback | Card + `ListItem`/row; `ACTION_SENDTO` `mailto:info@digitalyogin.com`; subject `Supporto Ditelo sui Tetti … v{version} ({build})`; `AlertDialog` if no mail app. Content desc: "Contatta il supporto tecnico Digital Yogin". |
| **Share button** | `ShareLink` over `ShareMessage` text (title + canonical `suitetti.org` URL + store link) | `Intent.ACTION_SEND` (text/plain) in `Intent.createChooser`; build the same invite text; use the Play Store URL. |
| **Promo banner** (`HomeReferendumCTA`) | dark gradient CTA card — **not rendered in v1.0** (kept for future) | optional future banner slot; do not render for v1.0. |

**Share text rule**: never share a raw or legacy URL — always the inviting message with the canonical `https://www.suitetti.org/…` link and the store listing.

---

## Addendum — HomeFeaturedEventCard (2026-08-12)

> Behaviour, data contract and QA live in **`FEATURED_EVENT.md`**. This section covers the visual + accessibility spec only.

**File:** `Components/Cards/HomeFeaturedEventCard.swift`, hosted by
`Screens/Home/HomeFeaturedEventSection.swift`.

Replaces the hardcoded "3° Festival" `HomePromoCard` slot on Home. `HomePromoCard` itself
remains in the codebase as a reusable component for future campaigns but is **no longer
rendered**. Nothing about this card is bound to a specific event.

**Visual spec**

- Solid `white` surface on `brandCream`, corner `22` (`DT.cornerRadius`), hairline
  `white @ 0.8` 0.5pt, `cardShadow()`. Deliberately solid, not glass: it carries body text.
- Cover: `RemoteImageView` height `170`, clipped, with a bottom
  `LinearGradient(clear → black 0.45)` at half the cover height so the pill stays legible.
  A missing/failed image falls back to the official brand artwork via `RemoteImageView` —
  no bespoke placeholder, no duplicated image loading.
- Pill: `CategoryChip("EVENTO IN EVIDENZA")`, `brandBlack` on `brandYellow`, padding `12`.
- Body padding `16`, spacing `12`: title (20 bold, kerning `-0.4`, max 3 lines) → meta rows
  (`calendar` + date·time, `mappin.and.ellipse` + location; 14pt `brandGray`, `brandRed`
  icons) → `Divider` (`brandSep`) → CTA row ("Scopri l'evento", 15 semibold `brandRed`) with
  a `34×34` `brandRed` arrow tile, corner `11`.
- Location row is omitted entirely when `location` is empty.

**Behaviour**

- The whole card is one `NavigationLink` → **native** `EventDetailView(event:)`. Never opens
  the website. Same detail screen used by `HomeEventsSection` and `EventiView`.
- Rendered only when `EventStore.featuredEvent != nil`; otherwise the section emits nothing —
  no placeholder, no reserved space.
- Home's "Prossimi eventi" preview filters the promoted event out so it never appears twice in
  one screenful. The full events list still shows it.

**Accessibility**

- One merged element: label `"Evento in evidenza. {title}. {date}. {location}"`, hint
  `"Apri i dettagli dell'evento"`, `isButton` trait. The cover is `accessibilityHidden`.
- Tap target is the entire card, far above 44pt.
- Dynamic Type via `@ScaledMetric` (title→`.title3`, meta/CTA→`.subheadline`, cover
  height→`.body`), so text and cover grow together instead of the image swamping the text.
- Reduce Motion: the card has no intrinsic animation; the section's `appearAnimation`
  already no-ops under Reduce Motion, and `PressableCardStyle` gates its scale.

**Compose parity:** `Card` + `Column`, Coil image with the same scrim and brand fallback,
pill, meta `Row`s with icons, `HorizontalDivider`, CTA row; `Modifier.clickable` navigating to
the existing event-detail destination; `semantics(mergeDescendants = true)` with the same
contentDescription; `sp` text with `FontScale`; render nothing when the flag resolves to null.
