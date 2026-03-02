# The Smith Agency — Admin Dashboard Rebuild

## What You're Building
A complete rebuild of the admin dashboard for **The Smith Agency**, a wholesale mart / fashion trade show staffing company. The current app works but has a dated design, Pages Router architecture, and localStorage-based auth. This rebuild modernizes everything while preserving all existing functionality.

The admin dashboard is used by the agency owner and managers to manage staff, clients, shows, and bookings. It connects to the same Firebase project as the iOS portal app.

## Tech Stack
- **Next.js 15** (App Router, Server Components where possible)
- **TypeScript**
- **Tailwind CSS v4** + custom design system
- **Firebase**: Firestore, Auth (email/password for admins), Storage
- **Zustand** for client-side state (keep what works)
- **OpenAI** for AI chat assistant (existing feature, port it over)
- **Twilio** for SMS (existing feature)
- **Stripe** (admin-side: viewing payment status, triggering final charges)
- No other UI libraries — no Headless UI, no react-datepicker, no react-calendar. Build custom components.

## Firebase Collections (existing — DO NOT change the schema)

### `staff`
```typescript
interface Staff {
  id: string;                          // Firebase Auth UID
  name: string;
  email: string;
  phone: string;
  location: string;                    // city, e.g. "Atlanta"
  address: string;
  college: string;
  dressSize: string;
  shoeSize: string;
  instagram: string;
  retailWholesaleExperience: string;
  resumeURL: string;                   // Firebase Storage URL
  headshotURL: string;                 // Firebase Storage URL
  payRate: number;
  applicationFormCompleted: boolean;
  applicationFormApproved: boolean;
  skills: string[];
  role: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `clients`
```typescript
interface Client {
  id: string;                          // Firebase Auth UID
  name: string;                        // company name
  companyName: string;
  email: string;
  website: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `shows`
```typescript
interface Show {
  id: string;
  name: string;
  startDate: string;                   // YYYY-MM-DD
  endDate: string;                     // YYYY-MM-DD
  location: string;                    // e.g. "New York, NY"
  venue: string;
  description: string;
  season: string;
  type: string;
  status: 'upcoming' | 'ongoing' | 'completed' | 'cancelled';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### `bookings`
```typescript
interface Booking {
  id: string;
  clientId: string;                    // ref → clients
  showId: string;                      // ref → shows
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  paymentStatus: string;               // 'deposit_paid' | 'final_paid' | etc.
  notes: string;
  datesNeeded: DateNeed[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface DateNeed {
  date: string;                        // YYYY-MM-DD
  staffCount: number;
  staffIds: string[];                  // refs → staff
}
```

### `availability`
```typescript
interface Availability {
  id: string;
  staffId: string;
  staffName: string;
  showId: string;
  showName: string;
  availableDates: string[];            // YYYY-MM-DD[]
  createdAt: Timestamp;
}
```

### `contacts` (client sub-data)
```typescript
interface Contact {
  id: string;
  clientId: string;
  name: string;
  email: string;
  phone: string;
  role: string;
}
```

### `showrooms` (client sub-data)
```typescript
interface Showroom {
  id: string;
  clientId: string;
  city: string;                        // ATL, LA, DAL, NYC, LV
  buildingNumber: string;
  floorNumber: string;
  boothNumber: string;
}
```

### `boardPosts` + `boardReplies` (internal message board)
```typescript
interface BoardPost {
  id: string;
  text: string;
  mentions: { id: string; type: string; label: string }[];
  createdBy: string;
  completed: boolean;
  createdAt: Timestamp;
}

interface BoardReply {
  id: string;
  postId: string;
  parentId: string | null;
  text: string;
  mentions: { id: string; type: string; label: string }[];
  createdBy: string;
  createdAt: Timestamp;
}
```

## Auth
Replace the current localStorage password check with **Firebase Auth (email/password)**. Create an `admins` collection in Firestore to whitelist admin emails.

```typescript
interface Admin {
  id: string;                          // Firebase Auth UID
  email: string;
  name: string;
  role: 'owner' | 'manager';
  createdAt: Timestamp;
}
```

Auth flow:
1. Login page with email + password
2. After Firebase Auth sign-in, check if user's UID exists in `admins` collection
3. If not an admin, sign them out and show error
4. Use Next.js middleware to protect all routes except `/login`
5. Store auth state in a React context, NOT localStorage

## Design System

### Brand
- **Primary pink**: `#E8A0BF` (light), `#D4749C` (medium), `#C0487A` (dark/hover)
- **Navy**: `#0F172A` (text), `#1E293B` (headings), `#334155` (secondary text)
- **Surface**: `#FFFFFF` (cards), `#F8FAFC` (page bg), `#F1F5F9` (hover/zebra)
- **Success**: `#10B981`, **Warning**: `#F59E0B`, **Error**: `#EF4444`, **Info**: `#3B82F6`

### Typography
- **Font**: Inter (via `next/font`)
- **Display**: 600 weight, tracking tight
- **Body**: 400 weight
- Scale: 12/14/16/20/24/30px

### Components to Build
- `Button` — primary, secondary, ghost, danger variants. Sizes: sm, md, lg
- `Card` — white bg, rounded-2xl, ring-1 ring-slate-200, shadow-sm
- `Badge` — status badges (pending=amber, confirmed=emerald, cancelled=red, completed=blue)
- `Input` / `Select` / `Textarea` — consistent form styling
- `Modal` — sheet-style slide up, backdrop blur
- `Table` — sortable columns, zebra rows, pagination
- `Tabs` — underline style
- `DatePicker` — custom, no library. Calendar grid, range selection for shows
- `Avatar` — headshot with fallback initials, status dot
- `Sidebar` — collapsible, icon-only on mobile
- `CommandPalette` — ⌘K global search across staff, clients, shows, bookings
- `Toast` — success/error notifications, auto-dismiss

## App Structure

```
src/
├── app/
│   ├── layout.tsx                     // Root layout with sidebar + providers
│   ├── page.tsx                       // Dashboard
│   ├── login/
│   │   └── page.tsx
│   ├── staff/
│   │   ├── page.tsx                   // Staff list with filters
│   │   └── [id]/
│   │       └── page.tsx               // Staff detail/edit
│   ├── clients/
│   │   ├── page.tsx                   // Client list
│   │   └── [id]/
│   │       └── page.tsx               // Client detail (contacts, showrooms, booking history)
│   ├── shows/
│   │   ├── page.tsx                   // Shows list with calendar view
│   │   ├── new/
│   │   │   └── page.tsx
│   │   └── [id]/
│   │       └── page.tsx               // Show detail (availability matrix, bookings)
│   ├── bookings/
│   │   ├── page.tsx                   // All bookings with filters
│   │   ├── new/
│   │   │   └── page.tsx               // Create booking (2-step: details → dates/staff)
│   │   └── [id]/
│   │       └── page.tsx               // Booking detail/edit
│   ├── board/
│   │   └── page.tsx                   // Internal message board
│   ├── sms/
│   │   └── page.tsx                   // SMS sending interface
│   └── api/
│       ├── chat/
│       │   └── route.ts               // OpenAI chat endpoint
│       ├── sms/
│       │   └── route.ts               // Twilio SMS
│       └── stripe/
│           └── charge-final/
│               └── route.ts           // Stripe final charge
├── components/
│   ├── ui/                            // Design system primitives
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Badge.tsx
│   │   ├── Input.tsx
│   │   ├── Select.tsx
│   │   ├── Modal.tsx
│   │   ├── Table.tsx
│   │   ├── Tabs.tsx
│   │   ├── DatePicker.tsx
│   │   ├── Avatar.tsx
│   │   ├── Toast.tsx
│   │   └── CommandPalette.tsx
│   ├── layout/
│   │   ├── Sidebar.tsx
│   │   ├── Header.tsx
│   │   └── MobileNav.tsx
│   ├── dashboard/
│   │   ├── StatsRow.tsx               // Key metrics cards
│   │   ├── UpcomingShows.tsx          // Next 5 shows
│   │   ├── RecentBookings.tsx         // Latest booking activity
│   │   ├── StaffingGaps.tsx           // Unfilled booking dates
│   │   └── QuickActions.tsx           // Create show, booking, etc.
│   ├── bookings/
│   │   ├── BookingCard.tsx
│   │   ├── BookingForm.tsx            // 2-step create/edit
│   │   ├── StaffAssignment.tsx        // Date-by-date staff assignment
│   │   ├── AutoAssign.tsx             // Smart assignment algorithm
│   │   └── DateStaffPicker.tsx        // Date range + staff count selector
│   ├── staff/
│   │   ├── StaffCard.tsx              // Grid card with avatar, stats
│   │   ├── StaffDetail.tsx            // Full profile view
│   │   └── AvailabilityMatrix.tsx     // Show availability across dates
│   ├── shows/
│   │   ├── ShowCard.tsx
│   │   ├── ShowCalendar.tsx           // Month view with show blocks
│   │   └── ShowDetail.tsx             // Availability + bookings for a show
│   ├── clients/
│   │   ├── ClientCard.tsx
│   │   └── ClientDetail.tsx           // Contacts, showrooms, booking history
│   └── chat/
│       ├── ChatPanel.tsx              // Slide-out AI assistant
│       └── ChatMessage.tsx
├── lib/
│   ├── firebase/
│   │   ├── config.ts                  // Firebase init
│   │   ├── auth.ts                    // Auth helpers
│   │   └── service.ts                 // Firestore CRUD + listeners
│   ├── store.ts                       // Zustand store (typed)
│   ├── openai.ts                      // OpenAI client + function defs
│   ├── twilio.ts                      // Twilio helper
│   └── utils/
│       ├── dates.ts                   // Date formatting, range generation
│       ├── booking.ts                 // Fill calculation, assignment algorithm
│       └── search.ts                  // Fuzzy search across entities
├── hooks/
│   ├── useAuth.ts                     // Auth context hook
│   ├── useFirestore.ts                // Generic Firestore subscription hook
│   └── useCommandPalette.ts           // ⌘K handler
└── types/
    └── index.ts                       // All TypeScript interfaces
```

## Pages Detail

### Dashboard (`/`)
Top row: 4 stat cards
- Total active staff (approved applications)
- Upcoming shows (next 30 days)
- Open bookings (pending + confirmed, not fully staffed)
- Revenue this month (sum of bookings with final_paid)

Below:
- **Upcoming Shows** — next 5 shows as compact cards with date, location, booking count
- **Staffing Gaps** — bookings where `totalAssigned < totalNeeded`, sorted by soonest date. This is the #1 action item.
- **Recent Activity** — last 10 creates/updates across all collections (use Firestore `orderBy updatedAt`)

### Staff (`/staff`)
- Grid of staff cards (avatar, name, location, shows worked, days booked, approval status)
- Filters: search, location, approval status, role
- Click → staff detail page with:
  - Profile info (editable inline)
  - Booking history (all bookings they've been assigned to)
  - Availability submissions
  - Pay rate (editable)
  - Headshot + resume links
  - Approve/reject application buttons

### Shows (`/shows`)
- Two views: List and Calendar (toggle)
- Calendar: month grid, show blocks spanning start→end date, color by status
- List: sortable table with name, dates, location, venue, status, booking count
- Filters: search, location, season, status, date range
- Click → show detail page with:
  - **Availability matrix**: dates as columns, staff as rows, cells = available (✓) / not available. This is the key view for assignment decisions.
  - **Bookings for this show**: list of all bookings, staffing fill status
  - Edit show details

### Bookings (`/bookings`)
- Table view with: client name, show name, date range, staff needed/assigned, status, payment status
- Filters: search, status, payment status, show, client
- Status pills: pending (amber), confirmed (green), cancelled (red), completed (blue)
- Fill indicator: progress bar showing assigned/needed ratio
- Click → booking detail page
- Create booking flow (same 2-step as current but better UI):
  1. Select client + show + status + notes
  2. Pick dates from show range, set staff count per date, assign staff from available pool
  - **Auto-assign button**: sorts dates by fewest available staff first, greedily assigns
  - **Mass assign**: dropdown of staff available for ALL selected dates
  - Staff dropdowns only show staff who submitted availability for that show+date AND aren't already booked

### Clients (`/clients`)
- List with company name, email, booking count, total revenue
- Click → client detail:
  - Contact people (CRUD)
  - Showroom locations (CRUD)
  - Booking history with this client
  - Total spend

### Board (`/board`)
- Internal message board (like a simple Slack channel)
- Posts with @staff and #show mentions (autocomplete)
- Threaded replies
- Mark posts as complete/open
- Filter by open/closed/all, filter by mention

### SMS (`/sms`)
- Send SMS to individual staff or bulk to a group
- Template messages (e.g., "You've been booked for {show} on {dates}")
- Message history (if Twilio supports retrieval, otherwise just a send interface)

### AI Chat Assistant
- Floating button bottom-right → slide-out panel
- Same OpenAI function-calling setup as current app
- Functions: query bookings, recommend staff, update records, query any collection
- Natural language: "Who's available for Dallas Summer?" → queries availability → shows results
- Action buttons: "Book @Sarah for Dallas" → prepares the update

## Booking Mechanics (preserve exactly)

The core scheduling logic:

1. **Shows** have a date range (startDate → endDate)
2. **Staff submit availability** per show: which dates within the range they can work
3. **Clients request bookings**: for a show, how many staff per date
4. **Admin assigns staff**: from the pool of available (and not-already-booked) staff

Assignment rules:
- Staff dropdown for a date ONLY shows staff where:
  - `availability` doc exists with `showId` matching AND `availableDates` includes that date
  - Staff is NOT in `staffIds` for that date in ANY other booking for the same show
  - Staff is NOT already selected in another slot for the same date in the current booking
- Auto-assign algorithm: sort dates by fewest available staff (hardest first), then greedily fill

Fill calculation:
- `totalNeeded = sum(datesNeeded[].staffCount)`
- `totalAssigned = sum(datesNeeded[].staffIds.filter(Boolean).length)`
- "Filled" = `totalAssigned >= totalNeeded`

## Key Implementation Notes

1. **Firestore listeners**: Use `onSnapshot` for real-time updates on bookings, availability, and board posts. Don't poll.
2. **Date handling**: Show dates are `YYYY-MM-DD` strings. Parse as local dates: `new Date(year, month-1, day)`. Never use `new Date("YYYY-MM-DD")` directly (timezone issues).
3. **Optimistic updates**: When assigning staff, update the UI immediately, then write to Firestore. Show a toast on success/failure.
4. **Server Components**: Use for initial page loads (staff list, shows list). Client components for interactive parts (filters, forms, assignment UI).
5. **No API routes for CRUD**: Use Firestore client SDK directly for reads/writes (the current app routes through API endpoints unnecessarily). Keep API routes only for external services (OpenAI, Twilio, Stripe).
6. **Mobile responsive**: Sidebar collapses to bottom nav on mobile. Tables become card lists. The agency owner uses this on her phone.
7. **Loading states**: Skeleton loaders for initial data, spinner for actions, disabled buttons during submits.
8. **Error boundaries**: Wrap each page section in an error boundary with retry.

## Environment Variables
```
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
OPENAI_API_KEY=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=
STRIPE_SECRET_KEY=
```

## What to Migrate
- ✅ All CRUD operations for staff, clients, shows, bookings
- ✅ Booking creation with date/staff assignment (full mechanic)
- ✅ Auto-assign and mass-assign algorithms
- ✅ AI chat with OpenAI function calling
- ✅ SMS sending via Twilio
- ✅ Board (internal message board with mentions)
- ✅ Staff approval workflow
- ✅ Availability viewing
- ✅ Admin logging

## What NOT to Migrate
- ❌ PWA / service worker (not needed, this is desktop-first)
- ❌ localStorage auth (replaced with Firebase Auth)
- ❌ Splash screen
- ❌ react-calendar / react-datepicker (build custom)
- ❌ react-sparklines (use simple CSS or skip)

## Priority Order
1. Auth + layout + sidebar + routing
2. Firestore service layer + types + Zustand store
3. Dashboard page
4. Shows CRUD + calendar view
5. Staff CRUD + detail pages
6. Bookings CRUD + assignment mechanics (most complex)
7. Clients CRUD + detail pages
8. AI chat panel
9. Board
10. SMS
11. Command palette (⌘K)
12. Polish: loading states, error boundaries, toasts, mobile responsive

Build it section by section. Make sure each section compiles and works before moving on.
