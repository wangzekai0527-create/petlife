# PetLife native app design

The user supplied three mobile interface references and a black line cat logo on November 11, 2026. This is an existing SwiftUI iOS application, not a marketing website. The references and user's requested white background take priority over website-specific theme dealers, hero layouts, image quotas and CSS checks in Hallmark and design-taste-frontend.

## Visual system

- White page background with restrained, nearly white neutral cards. Shared colors live in `PetLife/Shared/Theme.swift`.
- Login and home retain neutral typography. Feature palettes: album/recording vivid blue (#1769EF), services bright green (#20D477), social sunny yellow (#FFD52D), profile warm brown (#A86332). Every page keeps a white base; cards, chips and placeholder tiles use white fills and thin companion-color borders. Text uses darker shades of the feature color for contrast. No decorative gradients.
- Native system type. Page introduction 25 pt semibold, section titles 20 pt semibold, body 15–17 pt, metadata 12–13 pt. Respect system text scaling for controls and body content.
- Consistent 20–24 pt page gutters, 12–24 pt gaps and 16–24 pt rounded card surfaces. Main controls have at least 44 pt touch targets.
- White capsule primary actions with feature-colored text and outlines; clear disabled and loading states.
- Native Canvas animal line illustrations, inheriting the active feature palette: cat, dog, bird, turtle and rabbit. Decorative art is hidden from VoiceOver; navigation buttons retain spoken labels and selected-state traits.
- A floating five-destination navigation capsule. Content receives a bottom safe-area inset so its final rows can be scrolled above the navigation.
- Reduced Motion disables the custom press and authentication transition animations.

## Screens

- Login: wordmark, cat and bird, concise introduction, login/register selector, email and password. Registration reveals the existing nickname, optional phone and city fields. The three requested bottom marketing cards are removed.
- Home: greeting, actual account counters and four functional shortcut cards with animals.
- Social: matching entry precedes recommendations; existing profile, publishing, comment and chat routes remain.
- Services: compact turtle introduction, green selected category, service list with complete wrapping tags and animal image fallbacks.
- Album: white background, bird illustration, create action and existing timeline. Tags wrap without truncating.
- Profile: cat illustration and account details, pet archive, existing message center and sign-out action.

## Validation

Compile the native simulator target with Xcode. Inspect actual simulator screenshots of login and all five main screens. Browser-only skill linters do not validate SwiftUI and are not reported as passing. Preview screenshots use a separately built, temporary app with InMemoryPetBackend; the delivered app's authentication and Supabase data layer are unchanged.

## Feature palette update

All four feature areas include matching detail, creation and conversation colors. Shared animal drawings, card styling, primary buttons and navigation titles inherit an environment palette. Home shortcuts and active bottom tabs use their destination color. Uploaded photos and video overlays retain their original appearance.

## White surface refinement

Album and service introduction headings and descriptions use near-black text. Feature card text and animal colors remain blue, green, gold and brown. All rounded containers, tags, matching entry, placeholder tiles and action surfaces use white fills. Thin borders define the cards and selection states.

## Current user revision: black text with colored containers

Supersedes the preceding white-surface and colored-text guidance for three features. Album uses bright blue (#55AAFF), services vivid green (#20D477), social yellow (#FFD52D) card, tag, placeholder and action backgrounds. Their text, navigation labels, animal linework, borders and timeline stems use black. Pages remain white. Profile retains its previous brown text and white cards. The brighter blue supports legible black text. Shared surfaces and buttons inherit the feature palette, including home entry cards.

## Current refinement: pale feature surfaces and white home cards

Feature containers now use near-white blue (#F3F8FF), green (#F2FBF6), and yellow (#FFFBEC), retaining black text and borders. Home shortcut cards use independent white surfaces with blue, green and golden-yellow typography, outlines and animal drawings. The pet archive shortcut remains brown on white. Destination palettes do not inherit the shortcut colors.

## Profile monochrome revision

The profile area now uses black typography, icons, animal linework and borders on white cards and white pages. Its pet archive shortcut and related archive/message views inherit this monochrome profile palette. Other feature palettes remain unchanged.

## Language and chat controls

Home has a globe plus explicit English / 中文 switch in the navigation bar. Locale updates invalidate view bodies without rebuilding their identity, retaining navigation and forms. Application chrome is bilingual; user-authored names, biographies, posts and messages stay in their original language. Chat has a connection status, timestamp and read receipt, multiline composer, sending/failed states and idempotent retry. Public profile sharing is opt-in with a per-pet toggle. Display-only service providers do not show simulated chat.
