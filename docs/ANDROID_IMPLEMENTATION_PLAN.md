# Android Implementation Plan — Ditelo sui Tetti

Practical build plan for the Kotlin / Jetpack Compose Android app. Follow phases in order; each phase produces a runnable increment.

---

## Phase 1: Project Setup

**Goal**: A skeleton project that builds, runs on device, and has the dependency graph wired.

### Steps

1. **Create Android project** in Android Studio.
   - Package: `it.ditelosuitetti.app` (or equivalent)
   - Min SDK: 26 (Android 8.0) — covers ~98% of active devices
   - Target SDK: 35 (Android 15)
   - Language: Kotlin
   - Build system: Gradle KTS

2. **Add dependencies** (`build.gradle.kts`):
   ```kotlin
   // Compose
   implementation(platform("androidx.compose:compose-bom:2024.x.x"))
   implementation("androidx.compose.ui:ui")
   implementation("androidx.compose.material3:material3")
   implementation("androidx.compose.ui:ui-tooling-preview")
   implementation("androidx.navigation:navigation-compose:2.7.x")
   implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.x")

   // Network
   implementation("com.squareup.retrofit2:retrofit:2.x.x")
   implementation("com.squareup.retrofit2:converter-moshi:2.x.x")
   implementation("com.squareup.moshi:moshi:1.x.x")
   implementation("com.squareup.moshi:moshi-kotlin:1.x.x")
   implementation("com.squareup.okhttp3:okhttp:4.x.x")
   implementation("com.squareup.okhttp3:logging-interceptor:4.x.x")

   // Room
   implementation("androidx.room:room-runtime:2.6.x")
   implementation("androidx.room:room-ktx:2.6.x")
   kapt("androidx.room:room-compiler:2.6.x")

   // Images
   implementation("io.coil-kt:coil-compose:2.x.x")

   // PDF
   implementation("com.github.barteksc:android-pdf-viewer:3.2.0-beta.1")
   // Alternative: PdfiumAndroid for raw rendering

   // Push notifications
   implementation("com.google.firebase:firebase-messaging-ktx:23.x.x")
   implementation(platform("com.google.firebase:firebase-bom:32.x.x"))

   // Preferences
   implementation("androidx.datastore:datastore-preferences:1.0.x")

   // Timber (logging)
   implementation("com.jakewharton.timber:timber:5.x.x")
   ```

3. **Configure `AndroidManifest.xml`**:
   - Internet permission
   - `RECEIVE_BOOT_COMPLETED` if scheduling on-boot sync
   - `FirebaseMessagingService` declaration
   - `NotificationChannel` setup in `Application.onCreate`

4. **Set up Hilt** (or Koin) for dependency injection.

5. **Initialise Timber** in `Application.onCreate`:
   ```kotlin
   if (BuildConfig.DEBUG) Timber.plant(Timber.DebugTree())
   ```

**Deliverable**: App launches to a blank screen. Logcat shows Timber output. No crashes.

---

## Phase 2: Design Tokens

**Goal**: All colours, typography, and spacing match the iOS app exactly.

### Steps

1. **Define colors** in `ui/theme/Color.kt`:
   ```kotlin
   val BrandRed         = Color(0xFFE8192C)
   val BrandCream       = Color(0xFFF2EFE9)
   val BrandYellow      = Color(0xFFF5E84A)
   val BrandYellowLight = Color(0xFFFCEEFA)
   val BrandBlack       = Color(0xFF1A1A1A)
   val BrandGray        = Color(0xFF5E5E5E)
   val BrandGrayLight   = Color(0xFFA0A0A0)
   ```

2. **Define typography** in `ui/theme/Type.kt`:
   - Source for sans-serif: **Inter** (closest match to SF Pro)
   - Source for serif: **Lora** or **Crimson Text** (closest match to Georgia)
   - Download from Google Fonts and add as downloadable fonts or embedded assets

3. **Define spacing constants** in `ui/theme/Spacing.kt`:
   ```kotlin
   object Spacing {
       val padding = 16.dp
       val cornerRadius = 22.dp
       val smallCorner = 14.dp
       val sectionSpacing = 12.dp
   }
   ```

4. **Create `AppTheme`** composable wrapping `MaterialTheme` with the custom colour scheme and typography.

**Deliverable**: Theme preview renders with correct brand colours.

---

## Phase 3: API Layer

**Goal**: A working Retrofit client that can call the editorial sync endpoint and log results.

### Steps

1. **Define `ApiService`**:
   ```kotlin
   interface ApiService {
       @GET("functions/v1/sync-editorial")
       suspend fun syncEditorial(): EditorialSyncResponseDto

       @GET("functions/v1/sync-editorial")
       suspend fun syncEditorialDelta(@Query("since") since: String): EditorialSyncResponseDto

       @POST("functions/v1/register-push-token")
       suspend fun registerPushToken(@Body body: PushTokenRequest): PushTokenResponse
   }
   ```

2. **Build `OkHttpClient`** with:
   - `HttpLoggingInterceptor` (BODY level in debug, NONE in release)
   - Connect timeout 20s, read timeout 30s
   - Retry interceptor (up to 2 retries with exponential backoff for 5xx and network errors)
   - User-Agent header: `DiteloSuiTetti-Android/1.0`

3. **Build `Retrofit`** with:
   - `MoshiConverterFactory`
   - Custom `Moshi` instance with `KotlinJsonAdapterFactory`

4. **Date adapter** for Moshi that handles:
   - ISO 8601 with fractional seconds (`yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ`)
   - ISO 8601 without fractional seconds (`yyyy-MM-dd'T'HH:mm:ssZ`)
   - Date-only (`yyyy-MM-dd`) — return midnight UTC
   - Log and return null for unknown formats; never throw

5. **Wire via Hilt** as a `@Singleton` in a `NetworkModule`.

**Deliverable**: A manual test call to `syncEditorial()` returns parsed data. Logcat shows HTTP 200 and item counts.

---

## Phase 4: DTOs and Mappers

**Goal**: Full type-safe representation of the API response, with defensive per-item decoding.

### Steps

1. **Define DTOs** in `data/remote/dto/`:

   `ArticleDto`:
   ```kotlin
   data class ArticleDto(
       @Json(name = "id")                  val id: String,
       @Json(name = "titolo")             val titolo: String,
       @Json(name = "slug")               val slug: String,
       @Json(name = "categoria")          val categoria: String,
       @Json(name = "data_pubblicazione") val dataPubblicazione: Date?,
       @Json(name = "estratto")           val estratto: String,
       @Json(name = "contenuto")          val contenuto: String,
       @Json(name = "immagine_url")       val immagineUrl: String?,
       @Json(name = "updated_at")         val updatedAt: Date?,
       @Json(name = "sync_version")       val syncVersion: Int
   )
   ```

   `EventDto`:
   ```kotlin
   data class EventDto(
       @Json(name = "id")          val id: String,
       @Json(name = "titolo")      val titolo: String,
       @Json(name = "slug")        val slug: String,
       @Json(name = "tipo")        val tipo: String,
       @Json(name = "data_evento") val dataEvento: String,   // "YYYY-MM-DD" — not ISO datetime
       @Json(name = "ora")         val ora: String,
       @Json(name = "luogo")       val luogo: String,
       @Json(name = "descrizione") val descrizione: String,
       @Json(name = "link")        val link: String?,
       @Json(name = "immagine_url") val immagineUrl: String?,
       @Json(name = "updated_at")  val updatedAt: Date?,
       @Json(name = "sync_version") val syncVersion: Int,
       // Home featured banner. Nullable + defaulted: a missing key, an explicit null, or a
       // wrong type must all mean "not featured" and must never drop the event.
       @Json(name = "is_home_featured") val isFeatured: Boolean? = null
   )
   ```

   `DocumentDto` — write a **custom Moshi adapter** that:
   - Requires only `id`
   - Tries `titolo` then `title` for the title; defaults to `"Documento"`
   - Tries `tipo` then `type`; defaults to `""`
   - Tries `categoria` then `category`; defaults to `""`
   - Tries `descrizione` then `description`; defaults to `""`
   - Tries `url`, `file_url`, `document_url`, `link` for the PDF URL; null if none found
   - `sync_version` defaults to `0`
   - Never throws; any document that cannot supply a valid `id` UUID is skipped

2. **Per-item lossy decoding** in `EditorialSyncResponseDto`:
   ```kotlin
   // Custom Moshi adapter for lossy array decoding
   class LossyListAdapter<T>(private val elementAdapter: JsonAdapter<T>) : JsonAdapter<List<T>>() {
       override fun fromJson(reader: JsonReader): List<T> {
           val result = mutableListOf<T>()
           reader.beginArray()
           while (reader.hasNext()) {
               val peeked = reader.peekJson()
               try {
                   elementAdapter.fromJson(peeked)?.let { result.add(it) }
               } catch (e: Exception) {
                   Timber.w("Skipped array item: ${e.message}")
               } finally {
                   reader.skipValue()
               }
           }
           reader.endArray()
           return result
       }
       // toJson omitted (write-only)
   }
   ```

3. **Define domain models** in `domain/model/`:
   - `Article` (id, slug, category, title, date, fullDate, readTime, excerpt, body, imageUrl)
   - `Event` (id, slug, type, day, monthShort, fullDate, time, location, description, link, imageUrl, rawDate, isUpcoming, isPast, isUndated)
   - `Document` (id, slug, type, category, description, url, uploadedAt, updatedAt)

4. **Write mappers** in `data/mapper/`:
   - `ArticleMapper.toArticle(dto)` — formats date, calculates readTime from word count
   - `EventMapper.toEvent(dto)` — parses `dataEvento` as date-only, combines with `ora`
   - `DocumentMapper.toDocument(dto)` — formats `dataCaricamento`, handles null URL

**Deliverable**: Unit tests for all mappers pass. A malformed document in a test JSON array is skipped; remaining documents are returned correctly.

---

## Phase 5: Room Offline Cache

**Goal**: Sync data survives process death and is available immediately on next launch.

### Steps

1. **Define Room entities** in `data/local/entity/`:
   - `ArticleEntity` (mirrors Article domain model; no Color fields — recompute from palette on load)
   - `EventEntity` — includes `isFeatured: Boolean = false` (Home featured banner)
   - `DocumentEntity`

   > Adding `isFeatured` to an **existing** database must be an additive Room migration
   > (`ALTER TABLE cached_events ADD COLUMN isFeatured INTEGER NOT NULL DEFAULT 0`), never
   > `fallbackToDestructiveMigration()` — users keep their offline content and old rows read
   > `false`, the correct pre-sync state.

2. **Define DAOs**:
   ```kotlin
   @Dao
   interface ArticleDao {
       @Query("SELECT * FROM articles") fun getAll(): Flow<List<ArticleEntity>>
       @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun insertAll(items: List<ArticleEntity>)
       @Query("DELETE FROM articles") suspend fun deleteAll()
   }
   ```

3. **Define `AppDatabase`** with `@Database(entities = [...], version = 1)`.

4. **Add `lastSuccessfulSyncDate`** to `DataStore<Preferences>` (equivalent of `UserDefaults`).

5. **Repository pattern**:
   ```kotlin
   class EditorialRepository(
       private val api: ApiService,
       private val articleDao: ArticleDao,
       // …
   ) {
       fun articlesFlow(): Flow<List<Article>> = articleDao.getAll().map { entities ->
           entities.map { it.toArticle() }
       }

       suspend fun sync() {
           val response = api.syncEditorial()
           // Atomic replace: delete all → insert all
           db.withTransaction {
               articleDao.deleteAll()
               articleDao.insertAll(response.articles.map { it.toEntity() })
               // … events, documents
           }
       }
   }
   ```

6. **Cache-invalidation signature** — whatever hash/version decides whether to rewrite the
   cache **must include `isFeatured`**. Clearing the flag usually changes nothing else about
   the event, so a text-only signature keeps a stale `true` and flashes the banner on the next
   cold start. This bug was hit and fixed on iOS; see `FEATURED_EVENT.md` §7.

**Deliverable**: Kill the app while data is loaded. Reopen — data is visible immediately before network returns. Un-feature an event backend-side, sync, then cold-restart: the banner must **not** come back.

---

## Phase 6: ViewModels

**Goal**: `StateFlow`-based ViewModels that mirror the iOS store pattern exactly.

### Shared sealed state type

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T, val offlineWarning: Boolean = false) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
    object Empty : UiState<Nothing>()
}
```

### ArticleViewModel

```kotlin
@HiltViewModel
class ArticleViewModel @Inject constructor(private val repository: EditorialRepository) : ViewModel() {
    val uiState: StateFlow<UiState<List<Article>>> = repository.articlesFlow()
        .map { articles ->
            if (articles.isEmpty()) UiState.Empty else UiState.Success(articles)
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), UiState.Loading)

    fun refresh() { viewModelScope.launch { repository.sync() } }
}
```

### EventViewModel

```kotlin
val upcomingEvents: StateFlow<List<Event>> = repository.eventsFlow()
    .map { events -> events.filter { it.isUpcoming }.sortedBy { it.rawDate } }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

// Home featured banner — DERIVED, never stored. Because it is recomputed from the current
// event list, clearing is_home_featured backend-side makes the banner disappear on the next sync
// with no extra bookkeeping. resolveFeatured() applies the deterministic tiebreak.
val featuredEvent: StateFlow<Event?> = repository.eventsFlow()
    .map(::resolveFeatured)
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)
```

See `FEATURED_EVENT.md` §4.2 for `resolveFeatured()` and §5 for the full Android contract.

### DocumentViewModel

Same pattern as ArticleViewModel. Documents with null URL are included in the list.

### SyncViewModel (global)

Owned by the root `Activity`, orchestrates the launch sync:
1. Load Room cache → populate flows
2. Fire `repository.sync()` → update Room → flows update automatically
3. On failure with cache: set `offlineWarning = true`
4. On failure without cache: emit `Error` state

**Deliverable**: All ViewModels compile. Preview composables render with stub data.

---

## Phase 7: Compose Screens

Build screens in this order (each is a complete, navigable screen):

### 7.1 Navigation graph

```kotlin
NavHost(navController, startDestination = "home") {
    composable("home")      { HomeScreen(navController) }
    composable("articoli")  { ArticoliScreen(navController) }
    composable("documenti") { DocumentiScreen(navController) }
    composable("chi-siamo") { ChiSiamoScreen(navController) }
    composable("article/{id}") { ArticleDetailScreen(it.arguments?.getString("id")) }
    composable("event/{id}")   { EventDetailScreen(it.arguments?.getString("id")) }
    composable("document/{id}") { DocumentDetailScreen(it.arguments?.getString("id")) }
    composable("pdf/{url}") { PdfReaderScreen(it.arguments?.getString("url")) }
    composable("web/{url}") { WebPageScreen(it.arguments?.getString("url")) }
}
```

### 7.2 Bottom navigation

```kotlin
NavigationBar {
    NavigationBarItem(icon = { Icon(Icons.Filled.Home, null) },    label = { Text("Home") },     ...)
    NavigationBarItem(icon = { Icon(Icons.Filled.Article, null) }, label = { Text("Articoli") }, ...)
    NavigationBarItem(icon = { Icon(Icons.Filled.Folder, null) },  label = { Text("Documenti") }, ...)
    NavigationBarItem(icon = { Icon(Icons.Filled.Info, null) },    label = { Text("Chi siamo") }, ...)
}
```

### 7.3 Home screen

Components (in order, top to bottom):
- `HomeHero` — animated gradient background (use `Canvas` + Compose animation for the mesh gradient effect), brand typography "Ditelo" + "sui Tetti.", stats strip
- `HeroTicker` — scrolling ambient text strip (see iOS implementation notes)
- `HomeFeaturedArticlesSection` — vertical list of first 5 articles using `ArticleListRow`
- `HomeFeaturedEventCard` — **dynamic** featured-event banner, rendered only when
  `featuredEvent` is non-null; tap opens the native Event Detail. Emit nothing when null (no
  placeholder, no spacer). See `FEATURED_EVENT.md` §5
- `HomeEventsSection` — up to 3 upcoming events as cards, **excluding** the featured one;
  empty state if none; hide the whole section if the featured event was the only upcoming one
- `HomeQuoteSection` — static quote card
- Bottom padding: 130dp to clear the floating bottom navigation

> The old hardcoded festival/event CTA card is **gone**. Do not port it. The featured-event
> banner replaces it and is driven entirely by `events.is_home_featured`.

### 7.4 Articoli screen

- `ArticlesFilterBar` — horizontal scrolling category filter chips
- `ArticlesList` — full list, `LazyColumn` with `ArticleListRow`
- Pull-to-refresh with `SwipeRefresh` (Accompanist) or Compose `PullRefreshState`
- Skeleton loading state (shimmer effect)
- Empty / error states with retry button

### 7.5 Documenti screen

- `LazyColumn` of `DocumentListRow` items
- Each row: title, type/category chip, upload date, chevron
- If document has no URL, show a lock/unavailable icon instead of chevron
- Tap → `DocumentDetailScreen`
- Pull-to-refresh
- Skeleton loading state

### 7.6 DocumentDetailScreen

- Hero image or gradient placeholder
- Title, type chip, category, description
- "Apri PDF" button — disabled / replaced with "PDF non disponibile" if `url == null`
- Tap "Apri PDF" → navigate to `PdfReaderScreen`

### 7.7 Chi siamo screen

Sections:
1. Intro paragraph
2. Mission cards (Famiglia, Educazione, Sussidiarietà) — use Material icons
3. Support CTA card (dark gradient, "Sostienici" button → `Intent(ACTION_VIEW, websiteUrl)`)
4. Settings list:
   - Privacy Policy → `WebPageScreen(privacyUrl)`
   - Termini e condizioni → `WebPageScreen(termsUrl)`
   - Gestisci notifiche → `Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)`
   - Valuta l'app → `ReviewManager.requestReviewFlow()`
5. Developer info: version, build number, Digital Yogin srl attribution

### 7.8 Onboarding

- `HorizontalPager` with 3 slides
- `@DataStore` `hasSeenOnboarding` boolean gate
- Notification permission pre-prompt screen after slide 3
- After permission is resolved → navigate to `MainScreen`

**Deliverable**: All 4 tabs are navigable. Articles, events, and documents load and display real data.

---

## Phase 8: PDF Reader

**Goal**: PDFs open and render inside the app with a share button.

### Steps

1. **Download PDF** to `context.cacheDir` using OkHttp or DownloadManager.
   - Use content hash or URL hash as filename for cache-hit detection.
   - Show `CircularProgressIndicator` during download.

2. **Render PDF** using `barteksc/AndroidPdfViewer` or `PdfRenderer`:
   ```kotlin
   AndroidView(factory = { context ->
       PDFView(context, null).apply {
           fromFile(cachedFile)
               .enableSwipe(true)
               .swipeHorizontal(false)
               .enableAnnotationRendering(true)
               .load()
       }
   })
   ```

3. **Share button** in `TopAppBar` trailing slot:
   ```kotlin
   val uri = FileProvider.getUriForFile(context, "${context.packageName}.provider", cachedFile)
   val intent = Intent(Intent.ACTION_SEND).apply {
       type = "application/pdf"
       putExtra(Intent.EXTRA_STREAM, uri)
       addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
   }
   context.startActivity(Intent.createChooser(intent, "Condividi PDF"))
   ```

4. Add `FileProvider` to `AndroidManifest.xml`.

**Deliverable**: Tapping a document with a valid URL downloads and renders the PDF. Share intent produces a shareable file.

---

## Phase 9: WebView / Legal Pages

**Goal**: Privacy Policy and Terms pages open in an in-app browser.

### Option A: Chrome Custom Tabs (recommended)

```kotlin
CustomTabsIntent.Builder()
    .setToolbarColor(BrandRed.toArgb())
    .build()
    .launchUrl(context, Uri.parse(url))
```

No permissions needed. Handles SSL, history, and back navigation natively.

### Option B: WebView (closer to iOS implementation)

```kotlin
AndroidView(factory = { WebView(it).apply {
    settings.javaScriptEnabled = true
    webViewClient = WebViewClient()
    loadUrl(url)
}})
```

Add `INTERNET` permission. Handle back navigation in `BackHandler`.

### Steps

1. Create `WebPageScreen(title: String, url: String)` composable.
2. Show `TopAppBar` with title and back navigation.
3. Show `LinearProgressIndicator` while loading (using `WebChromeClient.onProgressChanged`).
4. Wire `privacyPolicyUrl = "${websiteUrl}/privacy"` and `termsUrl = "${websiteUrl}/termini"` from a constants file equivalent to `AppEnvironment`.

**Deliverable**: Tapping Privacy Policy opens the URL inside the app with a progress bar.

---

## Phase 10: Push Notifications

**Goal**: FCM token registered on the server; push taps deep-link to the correct content screen.

### Steps

1. **Add Firebase** to the project (`google-services.json`, Firebase plugin in `build.gradle`).

2. **Implement `FirebaseMessagingService`**:
   ```kotlin
   class DiteloMessagingService : FirebaseMessagingService() {
       override fun onNewToken(token: String) {
           // Register with server
           CoroutineScope(Dispatchers.IO).launch {
               PushTokenRepository.register(token)
           }
       }

       override fun onMessageReceived(remoteMessage: RemoteMessage) {
           // Show notification when app is foregrounded
           val data = remoteMessage.data
           val contentType = data["contentType"] ?: return
           val id = data["id"] ?: return
           val slug = data["slug"] ?: return
           showNotification(contentType, id, slug)
       }
   }
   ```

3. **Register token on first launch**:
   ```kotlin
   FirebaseMessaging.getInstance().token.addOnSuccessListener { token ->
       CoroutineScope(Dispatchers.IO).launch {
           PushTokenRepository.register(token)
       }
   }
   ```

4. **Deep link from notification tap**:
   - When notification is tapped, `MainActivity` receives an `Intent` with extras `contentType`, `id`, `slug`.
   - Parse these into a `NotificationDeepLink` and navigate to the appropriate screen.
   - Look up by `id` first; fall back to `slug`.

5. **New content detection** (optional):
   - After each successful sync, compare previous and fresh content IDs.
   - Post a local notification if a new article, event, or document is found.
   - Use `NotificationManager` with a `NotificationChannel` (Android 8+).

**Deliverable**: App receives a test FCM push notification in Firebase Console. Tapping the notification navigates to the correct content screen.

---

## Phase 11: QA / Internal Testing

**Goal**: Internal build distributed to testers via Firebase App Distribution (equivalent of TestFlight).

### Checklist

**Functional**
- [ ] Full sync on launch: articles, events, documents all load
- [ ] Pull-to-refresh refreshes data
- [ ] Offline cache: kill app, disable network, reopen — content visible
- [ ] Offline banner shown when network unavailable and cache exists
- [ ] Document with null URL shows "PDF non disponibile" — not filtered out
- [ ] Events with past dates do not appear on Home; empty state shown if all past
- [ ] PDF opens, renders, and shares correctly
- [ ] Privacy Policy and Terms open in-app
- [ ] "Gestisci notifiche" opens Android notification settings for the app
- [ ] "Valuta l'app" triggers Play In-App Review flow
- [ ] Version and build number correct in Chi siamo
- [ ] Push token registered on server (check `push_device_tokens` table)
- [ ] Notification tap navigates to correct content

**Resilience**
- [ ] Corrupt / partial JSON from server: app shows cached content, logs error
- [ ] One malformed document in array: remaining documents still load
- [ ] Image load failure: branded gradient placeholder shown (not broken icon)
- [ ] PDF download failure: error state with retry button (not crash)

**UI**
- [ ] All 4 tabs navigable without crash
- [ ] Back navigation works in all detail screens
- [ ] Content does not hide behind bottom navigation bar
- [ ] Dynamic type / large fonts do not break layouts
- [ ] Dark mode renders acceptably (or is explicitly disabled in theme)

**Distribution**
1. Set up `release` build variant with ProGuard rules for Moshi (keep `@Json` annotations)
2. Sign with upload keystore
3. Upload to Firebase App Distribution or Google Play Internal Testing track
4. Share with QA team

---

## Appendix: Constants

```kotlin
object AppConfig {
    const val BASE_URL       = "https://kbswgeliohnpwopzzzpc.supabase.co"
    const val WEBSITE_URL    = "https://comitaticivici.it"
    const val PRIVACY_URL    = "$WEBSITE_URL/privacy"
    const val TERMS_URL      = "$WEBSITE_URL/termini"
    const val SYNC_ENDPOINT  = "/functions/v1/sync-editorial"
    const val TOKEN_ENDPOINT = "/functions/v1/register-push-token"
}
```

## Appendix: Article Color Palette

The iOS app assigns gradient colors to articles deterministically: `index = id.bytes[0] % palette.size`. Replicate the same palette in Android so cached articles always render with the same colors. The full palette is defined in `Utilities/ArticleColorPalette.swift` in the iOS codebase.
