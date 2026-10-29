# GetSpot Design System — "Court & Shuttle"

GetSpot's visual language for the Flutter app (mobile + web). The goal is
sporty but restrained: a deep **court green** carries the structure, and the
logo's **shuttle orange** is reserved for the single most important action on
a screen.

All tokens live in [`lib/theme/`](../lib/theme). Import one file:

```dart
import 'package:getspot/theme/theme.dart';
```

`MaterialApp` uses `AppTheme.light`, `AppTheme.dark` and `ThemeMode.system`
(see `lib/main.dart`), so every screen supports dark mode automatically as
long as it reads colors from the theme.

## Rules

1. **No hardcoded colors in screens.** Don't use `Colors.red`, `Colors.green`
   or `Color(0x…)`. Use `context.colors` (`ColorScheme`) or `context.semantic`
   (`AppSemanticColors`). `Colors.transparent` is fine.
2. **No raw font sizes.** Use `context.textStyles.<role>` and `copyWith` for
   color/weight only. For money and counts, add `.tabular`.
3. **Spacing and radius come from tokens.** Use `AppSpacing.*` and
   `AppRadius.*`, not literal `8.0` / `16` values.
4. **Prefer stock Material widgets.** Component themes in `app_theme.dart`
   style `Card`, `FilledButton`, `TextField`, `Chip`, `ListTile`, dialogs,
   sheets and snackbars, so screens don't need `styleFrom` for the default look.
5. **Statuses go through `StatusBadge`.** Never pick a status color by hand.

## Tokens

### Color — `ColorScheme`

Built with `ColorScheme.fromSeed(seedColor: courtGreen, dynamicSchemeVariant: fidelity)`.
The key roles are then pinned:

| Role | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#1F6F50` court green | `#84D8B0` | Primary buttons, focus, links, icons in detail rows |
| `primaryContainer` / `on…` | `#BDEFD5` / `#002116` | `#00513A` / `#A6F2CC` | Date tiles, group avatars, empty-state icons |
| `secondary` | `#4C6971` logo slate | seed tonal | Rare. Supporting accents |
| `tertiary` | `#9C3F12` | `#FFB596` | Orange-family text accents (AA-safe) |
| `surface` | `#F7F8F5` | `#0F1512` | Scaffold / app bar background |
| `surfaceContainerLowest` | `#FFFFFF` | `#0A0F0C` | Cards (light) |
| `surfaceContainerLow` | `#F1F4EF` | `#161D19` | Cards (dark), dialogs, sheets |
| `surfaceContainerHigh` | `#E6E9E4` | `#252B28` | Input fill, neutral badge |
| `outlineVariant` | `#DCE2DC` | `#2E3833` | Card borders, dividers |
| `error` / `errorContainer` | M3 defaults | M3 defaults | Destructive actions, denied/penalty |

### Color — `AppSemanticColors` (ThemeExtension)

Read with `context.semantic` or `AppSemanticColors.of(context)`.

| Token | Light | Dark | Use |
|---|---|---|---|
| `success` / `successContainer` | `#1E7B3A` / `#D5F3DC` | `#7DD992` / `#15492A` | Confirmed, success snackbars |
| `warning` / `warningContainer` | `#A6510A` / `#FFE6C4` | `#F5B86A` / `#5A3A06` | Waitlisted, pending, low-balance warnings |
| `info` / `infoContainer` | `#1D5FA8` / `#D8E6FB` | `#9CC3F5` / `#173E6B` | Requested, join-request counts |
| `credit` | `#1E7B3A` | `#7DD992` | Positive amounts |
| `debit` | `#BA1A1A` | `#FFB4AB` | Negative amounts |
| `accent` / `onAccent` | `#FF6523` / `#240B00` | `#FF7A40` / `#240B00` | FAB ("Create event"). Use at most once per screen |
| `heroStart` → `heroEnd` | `#1F6F50` → `#0F4632` | `#1B5E44` → `#0C3022` | Wallet balance hero gradient |

Every `*` color has a matching `on*` color for text and icons placed on it.

### Typography

The platform font (Roboto on Android/web, SF on iOS) on the Material 3 scale,
with heavier weights for hierarchy:

| Role | Weight | Typical use |
|---|---|---|
| `displaySmall` | 700, -0.5 tracking | Wallet balance amount |
| `headlineSmall` | 700, -0.3 | Event title, date-tile day number |
| `titleLarge` | 700, -0.2 | App bar titles, dialog titles, empty-state titles |
| `titleMedium` | 600 | Card titles, section headers, list tile titles |
| `titleSmall` | 600 | Inline amounts, banner text |
| `bodyLarge` | 400 | Announcement body, transaction description |
| `bodyMedium` | 400 | Secondary lines (use `onSurfaceVariant`) |
| `bodySmall` | 400 | Fine print in dialogs |
| `labelLarge` | 600 | Buttons, tabs, chips |
| `labelMedium` | 600 | Status badges, meta lines |

`TextStyle.tabular` (an extension) turns on tabular figures so amounts line up.

### Spacing — `AppSpacing` (4-pt scale)

| Token | Value | Typical use |
|---|---|---|
| `xxs` | 2 | Between stacked meta lines |
| `xs` | 4 | Icon-to-text gaps, card vertical margin |
| `sm` | 8 | Between related elements, button groups |
| `md` | 12 | Card inner padding (dense), section gaps |
| `lg` | 16 | Page gutter, card padding |
| `xl` | 24 | Hero padding, between page sections |
| `xxl` | 32 | Large separations |
| `xxxl` | 48 | Hero/empty-state breathing room |

`AppSpacing.page` is `EdgeInsets.all(16)`.

### Radius — `AppRadius`

| Token | Value | Use |
|---|---|---|
| `sm` | 8 | Chips |
| `md` | 12 | Buttons, inputs, snackbars, date tiles, banners |
| `lg` | 16 | Cards, FAB |
| `xl` | 24 | Dialogs, bottom sheets, wallet hero |
| `full` | 999 | Status badge pills |

### Sizes — `AppSizes`

`buttonHeight` 48 (minimum touch target), icons `iconSm` 16 / `iconMd` 20 /
`iconLg` 24, `avatar` 40.

### Layout — `AppBreakpoints`, `AppContentWidth`

GetSpot runs on phones, tablets and the web, so content must not stretch edge
to edge on wide windows.

| Token | Value | Meaning |
|---|---|---|
| `AppBreakpoints.compact` | 600 | Below: phones in portrait |
| `AppBreakpoints.medium` | 840 | Below: small tablets, phones in landscape |
| `AppBreakpoints.expanded` | 1200 | Below: large tablets / laptops. Above: desktop |
| `AppContentWidth.form` | 560 | Forms, sign-in, create event |
| `AppContentWidth.reading` | 720 | Lists and detail screens (default) |
| `AppContentWidth.wide` | 1040 | Future multi-column / dashboard layouts |

Wrap each screen body in `ConstrainedContent`
(`lib/widgets/constrained_content.dart`). It centers the content and caps it
at `maxWidth`, and has no effect on phones:

```dart
body: SafeArea(
  child: ConstrainedContent(
    maxWidth: AppContentWidth.form,
    child: Form(...),
  ),
),
```

App bars, tab bars and bottom-bar backgrounds stay full width. Only their
content (for example the home screen's Join/Create buttons) is constrained.

### Elevation

Flat by default. Cards use elevation 0 with a 1px `outlineVariant` border, and
the app bar elevates to 1 only when content scrolls under it. Only the FAB
casts a shadow.

## Components

### Buttons

| Variant | Widget | Use |
|---|---|---|
| Primary | `FilledButton` / `.icon` | The main action (Register, Create group, Approve) |
| Secondary | `FilledButton.tonal` / `.tonalIcon` | Navigation-type actions (Members, My wallet, Update capacity) |
| Tertiary | `OutlinedButton` | Alternative to primary (Join group) |
| Destructive | `OutlinedButton` with `foregroundColor: colors.error` + error side | Withdraw, Cancel event |
| Destructive confirm (in a dialog) | `FilledButton` with `error` / `onError` | Final "Confirm withdrawal" |
| Text | `TextButton` | Dialog dismiss, low-emphasis inline actions |
| Accent | `FloatingActionButton.extended` | One per screen, picks up `accent` automatically |

All buttons are at least 48px tall with a 12px radius. **Loading:** keep the
label and swap the icon for a 20px `CircularProgressIndicator(strokeWidth: 2)`,
with `onPressed: null`. Don't replace the whole button with a spinner.
**Disabled:** `onPressed: null`. The theme handles the colors.

`ElevatedButton` is themed to look like a primary `FilledButton`, so screens
that haven't been migrated still match. New code should use `FilledButton`.

### Cards and list items

- `Card` gives a white (light) or `surfaceContainerLow` (dark) surface, a 16px
  radius, a 1px outline, a 4px vertical margin, and clipping for ink.
- For tappable cards, put an `InkWell` directly inside the `Card`, then
  `Padding(AppSpacing.lg or md)`.
- **Group row** (`GroupListItem`): a compact row meant to sit with others
  inside one `Card`, separated by `Divider(indent: 64)`. It has a
  rounded-square initial avatar, the name in `titleSmall`, and one summary
  line: the next event, "N members pending approval" (admins, in `info`), or a
  Pending badge. On the right is a **balance chip** that opens that group's
  wallet (red `errorContainer` when negative, neutral otherwise, at least 36px
  tall), then a chevron.
- **Upcoming game card** (`UpcomingEventCard`, Home): a `DateTile`, the title,
  and a meta line (`Sat 7:00 AM · location · group`). Below that is a capacity
  bar (`LinearProgressIndicator`, 6px, `primary`, or `warning` when full) with
  "12 of 16 spots" or "Full · 2 waiting". The last row is the `StatusBadge`
  plus, when the user isn't signed up, a compact **Register · $12**
  (`FilledButton`) or **Join Waitlist · $10** (`FilledButton.tonal`). Tapping
  the card opens Event Details.
- **Event card** (`_EventListItem`, Group details): a `DateTile`, then the
  title, time and location lines, and the `StatusBadge`.
- **DateTile** (`lib/widgets/date_tile.dart`): a 56px-wide month + day block
  on `primaryContainer` with a `md` radius. Use it at the start of any
  event card.
- **Transaction row:** a `CircleAvatar` with ↙ for credit (`successContainer`)
  or ↗ for debit (`errorContainer`). Description in `bodyLarge`, date as
  subtitle, amount in `titleMedium.tabular`.

### StatusBadge — `lib/widgets/status_badge.dart`

A tinted pill with an icon and label. Color, icon and localized label all come
from `StatusKind`.

| Kind | Colors | Icon | Default label |
|---|---|---|---|
| `confirmed` | success container | check_circle | Confirmed |
| `waitlisted` | warning container | hourglass_top | Waitlisted |
| `pending` | warning container | schedule | Pending (group membership) |
| `requested` | info container | schedule | Requested |
| `denied`, `penalty` | error container | cancel | Denied / Withdrawn (Penalty) |
| `notRegistered` | surfaceContainerHigh | radio_button_unchecked | Not Registered |

```dart
StatusBadge.fromParticipantStatus(participant['status'])   // from Firestore
const StatusBadge(kind: StatusKind.pending)
StatusBadge(kind: StatusKind.requested, label: l10n.groupItemPendingApproval(3))
```

The badge is never the only signal: the icon and the text both carry the
status, so it doesn't rely on color alone (WCAG 1.4.1).

### SectionHeader — `lib/widgets/section_header.dart`

`titleMedium` title with optional trailing `actions` (icon buttons, a small
tonal button). Replaces ad-hoc `Padding(Text(…, titleLarge))`.

### EmptyState — `lib/widgets/empty_state.dart`

A 72px tinted icon circle, a title, an optional message and an optional
action. Use it for empty lists and full-screen errors (`isError: true`
switches to error colors).

### Registration flow — `lib/helpers/event_registration.dart`

`startEventRegistration(context, eventId:, eventData:, onSubmitting:)` is the
one way to register for an event from any screen. It checks the wallet and
shows the matching dialog (normal, low balance, insufficient balance, or
waitlist), then writes the `requested` participant document. Event Details and
the Home cards both use it, so the money confirmation always looks and behaves
the same. Use `onSubmitting` to show a spinner on the button that started it.

### Inputs

`TextField` is filled with `surfaceContainerHigh` and has no border at rest, a
2px primary border on focus, and error borders when there's an error. Radius
is 12. **Don't** pass `border: OutlineInputBorder()`; the theme handles it.

### Chips

`ActionChip` / `Chip` have an 8px radius and an `outlineVariant` border. The
group code on Group Details is an `ActionChip` with a copy icon.

### Feedback

- **Snackbars** float with a 12px radius. Success: `backgroundColor:
  context.semantic.success`. Error: `colorScheme.error`. Neutral: no color.
- **Banners** (for example "Event cancelled"): a container in
  `errorContainer` / `warningContainer` with a 12px radius, a leading icon, and
  `titleSmall` text in the matching `on*Container` color.
- **Dialogs** have a 24px radius on `surfaceContainerLow`. Warning icons use
  `warning_amber_rounded` in `semantic.warning` or `colorScheme.error`.

### Wallet hero

A `heroStart → heroEnd` gradient with a 24px radius and 24px padding. The
label is `labelLarge` at 80% `onHero` and the amount is `displaySmall.tabular`
in `onHero`. Loading and error states stay inside the same hero so the layout
doesn't jump.

## Accessibility

- Primary on white, `onSurfaceVariant` on surfaces, and every `on*Container`
  pair are WCAG AA (4.5:1 or better) for body text.
- `shuttleOrange` (`#FF6523`) is **not** AA with white text, so the FAB uses
  dark `onAccent` text. Don't put white text on the accent.
- The minimum touch target is 48px (`AppSizes.buttonHeight`). Compact buttons
  inside dense rows (36px) are only allowed next to a full-size alternative.

## Migration status

| Area | Status |
|---|---|
| `main.dart` theme, light + dark | ✅ |
| Home: next games across groups, compact group rows, first-run state | ✅ |
| Group details (events, announcements, admin tabs) | ✅ |
| Event details (incl. dialogs and actions) | ✅ |
| Wallet | ✅ |
| Create event | ✅ Max width only (`form`). Fields pick up the input theme automatically |
| Login | ✅ Max width uses `AppContentWidth.form`. Some hardcoded `Colors.*` / `styleFrom` remain |
| Onboarding, verify email | ⏳ Theme applies automatically. Some hardcoded `Colors.*` / `styleFrom` remain |
| Group members, member profile, join group, FAQ, modals | ⏳ Same, and not width-constrained yet |

To migrate a screen: wrap its body in `ConstrainedContent`, remove `Colors.*`, `fontSize:` and per-button `styleFrom`
backgrounds, swap literal paddings for `AppSpacing`, and use `StatusBadge`,
`SectionHeader` and `EmptyState` where they fit. Then check it in both light
and dark mode.

## Changing tokens

1. Edit values in `lib/theme/app_tokens.dart` (raw palette, spacing, radius),
   `app_semantic_colors.dart` (semantic light/dark) or `app_theme.dart` (scheme
   overrides, type weights, component themes).
2. Keep light and dark in sync. Every semantic token needs both.
3. Check contrast for any new `on*` pairing.
4. Update this document.
