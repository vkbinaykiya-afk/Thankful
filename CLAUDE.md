# Thankful — Project Context

## What we're building
A voice-first gratitude journalling app for iOS and Android.
User speaks, AI listens and responds warmly, journal entry
is auto-generated from the conversation.

## Tech stack
- Framework: Flutter
- Backend: Supabase (auth, database, storage)
- STT: Deepgram Nova-2 (real-time WebSocket)
- TTS: Cartesia Sonic (streaming, chunk-based)
- LLM: Claude Haiku (reactions + entry generation)
- Payments: RevenueCat
- Analytics: PostHog
- Crash reporting: Sentry
- Marketing site: Framer

## Design system — LOCKED v2.0
Palette: Warm White
Font: Figtree via `google_fonts` (weights w400 and w500 only — NEVER w600 or w700)

Background:     #FAFAF8   0xFFFAFAF8
Surface:        #F0EDE6   0xFFF0EDE6
Surface raised: #E8E4DC   0xFFE8E4DC
Primary:        #5E9A78   0xFF5E9A78
CTA:            #E09050   0xFFE09050
Accent violet:  #7B6FA8   0xFF7B6FA8
Streak:         #E09050   0xFFE09050
Text primary:   #2C2416   0xFF2C2416
Text journal:   #5C4A3A   0xFF5C4A3A
Text secondary: #7A7060   0xFF7A7060
Text tertiary:  #A89E8E   0xFFA89E8E
Error:          #C0392B   0xFFC0392B
Monk maroon:    #6B2D2D   0xFF6B2D2D   (mascot art only — never UI)
Monk glasses:   #E8940A   0xFFE8940A   (mascot art only — never UI)

Border radius: 8 / 12 / 16 / 24 / 100 (full pill for all buttons)
Spacing unit: 6px base — xs 6, sm 12, md 18, lg 24, xl 36, xxl 48
Screen padding: 22px horizontal, 12px below status bar, 24px above home indicator

FORBIDDEN: gradients, drop shadows, pure white, pure black,
           font weights other than 400/500, all caps text,
           italic/underline outside legal hyperlinks,
           monk colours on UI elements, more than 3 colours per screen,
           CTA apricot and accent violet on the same screen.

Full spec: thankful_design_system_v2.md (status: LOCKED)

## Mascot
Young monk, round gold glasses, maroon robes, eyes always
closed. PNG assets per state:
- monk_namaste.png — sign up screen
- monk_meditation.png — home screen
- monk_writing.png — entry review
- monk_milestone.png — streak celebration (pending generation)
- monk_bowed.png — streak broken (pending generation)

Placement: always bottom corner, partially cropped
Zoom levels: vary per screen (see screen specs)

## App screens and flow
1. Sign up screen
   - USP copy hero
   - Apple / Google / Email auth
   - Monk namaste, bottom right, cropped at waist
   - Fade in animation on load (600ms ease out)

2. Demo voice session (auto-triggered post auth)
   - Monk greets user by name
   - One voice exchange
   - Entry generated from response

3. Paywall screen
   - Blurred entry preview behind paywall
   - $7.99/month or $44.99/year
   - 7-day free trial
   - RevenueCat implementation

4. Home screen
   - Monk meditation pose, bottom right
   - Streak counter
   - Past entries list
   - Start session CTA

5. Voice session screen
   - Monk listening/speaking states
   - Real-time waveform visualisation
   - Streaming voice pipeline

6. Entry review screen
   - Monk writing pose
   - Generated entry editable text
   - Save button

## Voice session architecture
- Deepgram WebSocket — real-time STT
- Streaming Claude Haiku — reactive responses
- Cartesia chunk-based streaming TTS
- Cached audio for static prompts
- Dynamic TTS for reactive responses only (~15 words)
- Target end-to-end latency: under 1 second
- Session structure: 3 prompts, 3 responses, ~3-5 minutes

## Personalisation levels (MVP)
- Level 1: User name + question rotation (pool of 20 prompts)
- Level 2: Reactive responses to current session input
- Level 3: Persistent user context injected into system prompt

## AI cost per user per month
- Base sessions (15/month): $0.29
- Reactive TTS: included above
- Reflection (post-MVP): ~$0.29 additional
- Total MVP: ~$0.29/user/month
- Gross margin at $7.99: ~96%

## Monetisation
- Free: demo session only
- Paid: $7.99/month or $44.99/year
- 7-day free trial ("Your first week is free")
- RevenueCat for subscription management
- Apple Small Business Pro (15% cut) — apply day one
- Google Play (15% cut — first $1M)

## Out of scope for MVP
- Reflection sessions (post-launch)
- Shareable cards (post-launch)
- PPP pricing (post-launch)
- Biometric lock (post-launch)
- Mascot animations via Rive (post-launch)
- Social features (never — not our model)

## Build sequence
1. Voice pipeline spike — prototype before any UI
2. Supabase schema + auth setup
3. Sign up screen
4. Demo voice session
5. Paywall — RevenueCat
6. Home screen
7. Full voice session flow
8. Entry review screen
9. App Store assets + submission
10. Marketing website — Framer

## Critical technical risks
1. WebSocket voice pipeline latency — must prototype first
   Target: <1 second end-to-end
2. Flutter audio streaming differences iOS vs Android
3. App Store review — budget 2-3 week wait, one rejection likely
4. GDPR consent screen before any data collection fires
5. RevenueCat + StoreKit 2 — follow docs exactly, no improvising
6. Supabase RLS — audit after setup, silent security risk

## Environment variables needed (.env)
SUPABASE_URL=
SUPABASE_ANON_KEY=
DEEPGRAM_API_KEY=
CARTESIA_API_KEY=
ANTHROPIC_API_KEY=
REVENUECAT_APPLE_KEY=
REVENUECAT_GOOGLE_KEY=
POSTHOG_API_KEY=
SENTRY_DSN=

## Supabase tables needed
- users (id, name, email, created_at, context_profile)
- journal_entries (id, user_id, content, session_transcript,
  created_at, session_date)
- streaks (user_id, current_streak, longest_streak,
  last_session_date)
- prompt_pool (id, prompt_text, category, active)

## Do not
- Use 600 or 700 font weights
- Add gradients or drop shadows to UI
- Build reflection sessions yet
- Add social features
- Skip RLS setup on Supabase tables
- Hardcode API keys anywhere

## Additional notes
- First action before building any feature: prototype
  voice pipeline in isolation
- All API keys via flutter_dotenv, never hardcoded
- Target devices: iPhone 12+ and Android equivalent
- Minimum iOS: 15.0, minimum Android: API 26

## App Store requirements checklist (before submission)
- Privacy policy URL live on domain
- Microphone permission string descriptive
- No mental health claims in copy
- GDPR consent before data collection
- RevenueCat restore purchases button present
- Age rating: 17+ (to avoid COPPA)
- iubenda policy live and linked
