# Aangan Mandi

Hyderabad residents lend a driveway or courtyard to a verified farmer for a few hours; nearby buyers get an alert.
Full spec: https://claude.ai/artifact/4DJDSrdotaz8CsbePR3yov

```
mobile/    Flutter 3.47 app, Android + web (Riverpod, go_router, Dio, Hive CE, en/te/hi) — one app for every role
backend/   .NET 8 modular monolith
  src/AanganMandi.Domain          entities
  src/AanganMandi.Application     use cases, interfaces
  src/AanganMandi.Infrastructure  EF Core + SQL Server (NetTopologySuite), file storage
  src/AanganMandi.Api             REST API /api/v1 (JWT, Serilog, Swagger) — used by the app; staff endpoints under /ops
  tests/AanganMandi.Tests         xUnit
```

## Roles

Farmer, Host and Buyer are chosen by the user on the role screen. **Verifier and Admin are never selectable**:
an admin adds or removes verifiers in the app, and admins are created on the server only (dev seed).
Staff accounts open the **Operations** home after login, on web and on phones. Staff endpoints re-check the
role in the database on every call, so a removed verifier loses access at once.

## What works today

| Flow | Who | Where |
|---|---|---|
| Language (en/te/hi), OTP login (test OTP shown on screen in Development), choose role | everyone | app |
| My profile (account details, farming details or spaces), light / dark / system theme, language, log out | everyone | app → profile icon |
| Documents (evidence photo, space photos, proof): preview and download always; reupload and delete until approved. Deleting something a waiting submission needs takes it back to "not submitted" / Draft | farmer, host | app (farmer home, space page) |
| Preview and download every document under review (staff never change them) | verifier, admin | app → Operations |
| Farmer verification: name, village, district, crops, farm size (optional), grows own or sources → one proof (AgriStack Farmer ID, land/cultivation record, FPO membership, or officer/organisation reference) with photo → submit | farmer | app |
| Dashboard; add or remove verifiers; see all farmers, assign or reassign; a removed verifier's queue moves to the others | admin | app → Operations |
| Submissions go to the verifier with the fewest waiting (resubmissions to the same one); verifier reviews only their own, approves (Level 2) or rejects with reason; farmer fixes and resubmits | verifier | app → Operations |
| List a space: details, location, amenities, days/hours, fee, 3–8 photos, private right-to-use proof → submit | host | app |
| Plan a trip (date up to 60 days ahead, vehicle, crops with optional kg and ₹/kg, preferred area) → find live spaces open that weekday that fit the vehicle and are free that day → request one; cancel the request, the booking or the whole trip | verified farmer | app → home → My trips |
| Booking requests per space and day: accept (other requests for that day are declined automatically) or decline with a reason; cancel a confirmed booking with a reason. Address and both phone numbers are shared only once accepted (FR-1.9); the fee is paid to the host at the space | host | app → home → Bookings |
| Approve space (goes Live) or reject with reason; host fixes from the space page | verifier, admin | app → Operations |
| Delete a whole space, in any status (see [Deleting](#deleting)) | host | app → space page → delete icon |
| Clear verification and start over, until verified; remove a typed-in crop with its ✕ | farmer | app → farmer home → "Clear and start over"; crop picker |
| On the booking day, "I've arrived" check-in at the space (see [Booking day and nearby buyers](#booking-day-and-nearby-buyers)) | verified farmer | app → My trips → the trip |
| See when the farmer arrived; mark "Didn't come" once the slot is over without a check-in | host | app → Bookings, and the host home |
| Save a home location + radius (1, 2 or 5 km); see farmers selling nearby today and tomorrow; email alerts the evening before and when a farmer arrives | buyer | app → buyer home |
| Share a confirmed stall with neighbours: a ready message + public link, sent to a WhatsApp group or copied (see [Sharing with neighbours](#sharing-with-neighbours)) | host | app → Bookings → Upcoming, and the host home |
| Open a shared stall link: time, crops and prices, area; the address once the farmer arrives. No app or login | anyone | browser |
| Delete my account (see [Deleting](#deleting)) | farmer, host, buyer | app → My profile → "Delete my account" |
| Success and error pop-ups: a green card that fades for "done", a dialog with OK for "that didn't work" (no internet, the server's reason, or "a problem on our side") | everyone | app |
| Every refusal from the API in the user's language, with a stable code (see [Errors in three languages](#errors-in-three-languages)) | everyone | app |
| Terms of use and privacy policy accepted once after login (again when they change) | everyone | app → consent screen; My profile → Terms of use / Privacy policy |
| Report a problem about a booking or the app; see the team's answer | farmer, host, buyer | app → a booking → Report a problem; My profile → Report a problem / My reports |
| Problem reports: open and resolved, call the reporter, resolve with a note they see | admin | app → Operations → Reports |
| Reminder the evening before a booking | farmer, host | email |

Not built yet: in-app payment, produce browsing beyond the nearby list, maps, push notifications (alerts and booking news arrive by email, and in the app when it is opened).

## Toolchain (installed on this machine)

| Tool | Location |
|---|---|
| Flutter 3.47.9 / Dart 3.13 | `C:\dev\flutter` |
| Android SDK (platform 36, build-tools 36.1, NDK 28.2) | `%LOCALAPPDATA%\Android\Sdk` |
| JDK 17 (Microsoft OpenJDK) | `C:\Program Files\Microsoft\jdk-17.*` |
| .NET 8 SDK (pinned by `backend/global.json`) + `dotnet-ef` 8 | |
| SQL Server (default instance `localhost`) | database `AanganMandi` |

## Run it

First time on a machine, set the JWT signing key (kept in .NET user secrets, outside the repo):

```bash
dotnet user-secrets set Jwt:Key "<random string, 64+ characters>" --project backend/src/AanganMandi.Api
```

In VS Code, open the `C:\Aangan_Mandi\Aangan_Mandi` folder, Run and Debug, pick **"Everything: API + Flutter (Chrome)"**, press F5.
For the Android emulator or a phone, pick **"API + Flutter app (phone / emulator)"**.

Or in two terminals:

```bash
dotnet run --project backend/src/AanganMandi.Api --launch-profile http
```
```bash
cd mobile && flutter run -d chrome --web-port 5090
```

| What | URL |
|---|---|
| API + Swagger | http://localhost:5080/swagger |
| App on Android emulator | calls `http://10.0.2.2:5080/api/v1` |
| App on a phone on Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<PC-IP>:5080/api/v1` |

### Android APK (to install on a phone)

The phone must reach the API on your PC over Wi-Fi, so bake in the PC's IP (`ipconfig` → Wi-Fi IPv4):

```bash
cd mobile && flutter build apk --release --dart-define=API_BASE_URL=http://<PC-IP>:5080/api/v1
```

Copy `mobile/build/app/outputs/flutter-apk/app-release.apk` to `C:\Aangan_Mandi\release`. Keep the API running (it
listens on `0.0.0.0:5080`), allow port 5080 in Windows Firewall, and rebuild the APK if the PC's IP changes. The
release build is signed with the debug key and allows plain HTTP (`usesCleartextTraffic` in
`android/app/build.gradle.kts`): fine for testing, change both before a Play Store release.

Pending migrations apply automatically when the API starts in Development.
New migration:

```bash
dotnet ef migrations add <Name> -p backend/src/AanganMandi.Infrastructure -s backend/src/AanganMandi.Api -o Persistence/Migrations
```

## Test logins (Development only, OTP `123456`)

| Mobile | Account | Use in |
|---|---|---|
| 9000000001 | Farmer — Ramesh Reddy | app |
| 9000000002 | Host — Lakshmi Prasad | app |
| 9000000003 | Buyer — Anjali Sharma | app |
| 9000000004 | New user, no role (role screen) | app |
| 9000000008 | Ops admin | app → Operations |
| 9000000009 | Ops verifier | app → Operations |

Other numbers get a random OTP. With `Otp:ShowDevCode` on (Development settings) it is shown on the OTP
screen; it is also printed in the API console as `DEV OTP for +91…`.

Uploaded photos are stored in `backend/App_Data/uploads` (git-ignored). KYC and proof files are served only
to signed-in staff (`/api/v1/ops/files/...`); the public files endpoint serves space photos only.

## Email

Sent with **Kinichit.Communication** (team library, used as a DLL: `backend/lib`, see its README). Users add an email
address in My profile (optional; admins can also give one when adding a verifier). Every email is in the recipient's app
language (English, Telugu, Hindi) and uses one branded layout (`Infrastructure/Notifications`: `MailText.cs` for the
wording, `MailLayout.cs` for the HTML).

| When | Who gets it |
|---|---|
| Farmer submits verification | the farmer, and the verifier it is assigned to |
| Admin (re)assigns a farmer | that verifier |
| Farmer approved / rejected (with reason) | the farmer |
| Admin adds a verifier | the new verifier (welcome) |
| Host submits a space | the host, and every admin |
| Space approved / rejected (with reason) | the host |
| Farmer requests a space | the host |
| Host accepts (address, phone, time, fee) / declines / cancels | the farmer (others declined automatically are told the day is taken) |
| Farmer cancels | the host |
| Farmer checks in at the space | the host ("your farmer is here"), and buyers whose area covers the space ("selling now", with the address) |
| Every evening at 18:00 India time | each buyer with tomorrow's confirmed stalls inside their area: one email listing time, area, distance, farmer and crops |
| Every evening at 18:00 India time | the farmer and the host of each confirmed booking for tomorrow: a reminder with time, address or farmer, phone and crops (once per booking, `Booking.ReminderSentAt`) |
| Someone reports a problem | every admin (category, who, the booking, what they wrote) |
| An admin resolves a report | the person who reported it, with the admin's note |

Emails are **queued** in this database (`dbo.EmailQueueItems`, created on first use) and a **Hangfire** job sends them
every 15 seconds, retrying failures (1, 5, 15, 60 min). A failed email never fails the action that triggered it.

- **Development** saves each email as a `.eml` file in `backend/App_Data/mail` (double-click to open in Outlook) instead of
  sending it.
- **Real sending**: in `appsettings.Production.json` (or user-secrets) set `Email:Provider` to `Smtp` with
  `Email:Smtp:Host`, `Username`, `Password` (port 587), or to `SendGrid` with `Email:SendGrid:ApiKey`, plus
  `Email:FromAddress` and `Notifications:AppUrl`. Keep passwords and keys out of git, e.g.
  `dotnet user-secrets set Email:Smtp:Password "<app password>" --project backend/src/AanganMandi.Api`.

## Booking day and nearby buyers

**Check-in.** On the booking day the farmer's trip shows **I've arrived**. The app sends the phone's GPS position, and
`POST /api/v1/farmers/me/trips/{id}/bookings/{bookingId}/arrive` accepts it only when (rules in `ArrivalRules`):

- the booking is confirmed (Accepted) and not checked in yet;
- it is the booking's date, from 1 hour before the slot starts until the slot ends (India time);
- the phone is within **200 m** of the space; otherwise the answer says how far it is ("about 1400 m").

The booking keeps `ArrivedAt` and `ArrivalDistanceMeters`. The host gets an email and sees "Arrived at 12:17" on the
booking and the host home. Once the slot is over without a check-in, the host can mark **Didn't come**
(`POST /api/v1/hosts/me/bookings/{id}/no-show`, saved as `NoShowAt`; no email).

**Nearby buyers.** A buyer saves a home location (GPS) and a radius of 1, 2 or 5 km (`PUT /api/v1/buyers/me/area`,
table `BuyerAreas`; `DELETE` forgets it). Then:

- the buyer home lists confirmed stalls inside that radius for the rest of today and tomorrow
  (`GET /api/v1/buyers/me/nearby`), farmers who have checked in first as **Selling now**;
- the exact address shows only while the farmer is there; before that, only the area and distance;
- with email alerts on and an email in My profile, they get the evening digest (Hangfire job `nearby-day-before`, 12:30
  UTC = 18:00 India) and a "selling now" email when a farmer checks in. `NearbyAlerts` records each one, so a buyer never
  gets the same alert twice. The booking's own farmer and host are never alerted.

Distances use SQL Server `geography` (metres). Migration: `ArrivalAndNearbyAlerts`.

## Sharing with neighbours

Neighbours who are not in the app hear about a stall from the host, who already belongs to their society or street
WhatsApp group. The app never messages people who have not signed up (no consent, and SMS/WhatsApp rules forbid it).

- **Host:** on a confirmed booking whose slot is not over, **Share with neighbours** opens a ready message in the host's
  language (date, time, space, crops with prices, link) with **Share on WhatsApp** (opens WhatsApp's chat picker via
  `wa.me`) and **Copy message**. `POST /api/v1/hosts/me/bookings/{id}/share` returns the link; the first call gives the
  booking a random 10-character `ShareCode`, later calls return the same link.
- **Public page:** `GET /s/{code}`, served by the API as plain HTML, no login. It shows the farmer's first name and
  village, the time, the crops and prices, and the space name and area. The exact address and a map link appear only
  while the farmer is checked in and the slot is running; a cancelled, no-show or finished stall says it is over.
  English, Telugu or Hindi (`?lang=`, else the browser's language); Open Graph tags give WhatsApp a preview card;
  `noindex`, cached for 60 seconds, no scripts.
- **Link address:** `Sharing:PublicBaseUrl` in appsettings (e.g. `https://api.aanganmandi.in`). Empty = the address the
  host's app used, which works on a local network (`http://<PC-IP>:5080/s/...`).

Migration: `BookingShareCode`.

## File storage

Uploaded files (farmer proofs, space photos and proofs) go through `IFileStorage`. `Storage:Provider` picks where:

- **Local** (Development default): `backend/App_Data/uploads` (git-ignored).
- **Object** (production default): the product's E2E Object Storage bucket, through
  [StorageProvider](https://github.com/SantoshRamancha/StorageProvider) (`backend/lib/StorageProvider`). Files sit under
  `Storage:KeyPrefix` (`dev` locally, `prod` in production) so environments never mix. The bucket stays private: the
  API streams every file, and proofs are only served to staff.

The endpoint (`StorageProvider:ServiceUrl`, E2E Chennai `https://in-south1-objectstore.e2enetworks.net`) is not a secret
and is already in `appsettings.json`; don't set it in user-secrets, where it would override that. To use the bucket on
your PC, set these in your own terminal (the keys never go in appsettings or git), then restart the API:

```bash
dotnet user-secrets set Storage:Provider Object --project backend/src/AanganMandi.Api
dotnet user-secrets set StorageProvider:BucketName "<bucket name>" --project backend/src/AanganMandi.Api
dotnet user-secrets set StorageProvider:AccessKey "<access key>" --project backend/src/AanganMandi.Api
dotnet user-secrets set StorageProvider:SecretKey "<secret key>" --project backend/src/AanganMandi.Api
```

Files uploaded before the switch are still on disk, and records that point at them show nothing until they are in the
bucket. Copy them once (files already in the bucket are skipped):

```bash
dotnet run --project backend/src/AanganMandi.Api -- copy-uploads-to-bucket
```

If the build fails with "file is locked by AanganMandi.Api", the API is still running (e.g. from Visual Studio): stop it
first, or add `--no-build` to reuse the build it is running.

On a server use environment variables instead, e.g. `StorageProvider__SecretKey`. A missing setting fails on the
first file request with an error naming it.

## Deleting

Every delete asks for confirmation in the app, and removes the files from storage (the bucket or disk) as well as the
database.

| What | Endpoint | Allowed | What happens |
|---|---|---|---|
| Evidence photo | `DELETE /api/v1/farmers/me/evidence/photo` | until verified | A waiting submission goes back to "not submitted" |
| Farmer's verification | `DELETE /api/v1/farmers/me/verification` | until verified | Village, district, farm size, produce source, crops, evidence and the evidence photo are cleared; status back to "not started" (a waiting submission leaves the verifier's queue). The name stays, and so does the assigned verifier for the next submission |
| Space photo or proof | `DELETE /api/v1/hosts/me/spaces/{id}/photos/{photoId}` | until the space is live | A waiting space with fewer than 3 photos or no proof goes back to Draft |
| Whole space | `DELETE /api/v1/hosts/me/spaces/{id}` | any status | Photos and proof are deleted; the space leaves search, the review queue and My spaces. Waiting and confirmed bookings from today on are cancelled by the host with the reason "The host removed this space from Aangan Mandi", and each farmer gets the usual cancellation email. Returns `{ cancelledBookings }` |

A deleted space is only marked `IsDeleted` (an EF query filter hides it), so past bookings still show its name. Booking
lists and booking emails read spaces with `IgnoreQueryFilters()` for that reason; other queries never see deleted spaces.

**Whole account** (`DELETE /api/v1/users/me`, app → My profile → Delete my account, after a tick box): upcoming bookings
are cancelled and the other side told; planned trips are cancelled; the farmer's verification details, crops, plots and
evidence photo, the host's spaces with their photos and proof, and the buyer's area and alert history are deleted. The
name and email are cleared, the phone is replaced by a placeholder (so the number can sign up again as a new user), and
roles and logins are removed. Past bookings stay for the other side without the name. Verifier and admin accounts are
refused (409): an admin removes them, so their waiting farmers are reassigned. Any token of a deleted account is
refused with 401 from then on.

The Play Store also asks for a web page about deleting an account: `GET /account/delete` (English, Telugu, Hindi;
`Support:Email` adds "can't open the app? write to …").

## Before going live

These are in the code; the deployment itself (server, HTTPS, domain) is not set up yet.

**Commands** (run with the published API, e.g. `dotnet AanganMandi.Api.dll <command>`, or `dotnet run --project
backend/src/AanganMandi.Api -- <command>` locally). Each does its job and exits without serving:

| Command | What it does |
|---|---|
| `migrate` | Applies pending database migrations. Run on every deploy before starting the new version (Development migrates on start) |
| `create-admin +919000054321 "Name"` | Makes that mobile number an admin, creating the user if needed. The first admin on a fresh database; admins can't sign up in the app |
| `copy-uploads-to-bucket` | One-time copy of files uploaded to disk before switching to the bucket |

**Login limits** (no SMS costs run away, no OTP guessing):

- The number must be an Indian mobile (10 digits starting 6–9; `+91`, spaces and dashes are fine).
- Per number: a new OTP at most every 30 seconds and 5 per hour (`429` with `Retry-After`).
- Per code: 5 tries, valid 5 minutes, works once; a typo no longer throws the code away.
- Per IP address: 20 OTP requests or checks per 10 minutes. Behind a reverse proxy, set up forwarded headers so the API
  sees the client's address.
- The limits are kept in memory, so they reset on restart and count per server.

**Settings** (none are secrets; all are in `appsettings.json`, empty by default):

| Setting | Use |
|---|---|
| `Cors:AllowedOrigins` | The web app's address(es) allowed to call the API from a browser, e.g. `["https://app.aanganmandi.in"]`. Development also allows any localhost port. The Android app needs nothing here |
| `Logs:Directory` | Where log files go (default `logs` next to the app; Development: `backend/App_Data/logs`) |
| `Alerts:Emails` | Who gets an email when the API logs errors; `MinMinutesBetween` (15) and `CollectSeconds` (60) keep it to one email per burst |
| `Support:Email` | Contact on `/account/delete` and on the terms and privacy pages (grievances) |
| `Sharing:PublicBaseUrl` | The public API address in shared stall links |

**Logs and alerts.** Besides the console, the API writes one file per day (`api-YYYYMMDD.log`, kept 30 days, at most
20 MB a file) with the time, level, source, request path and message. Every Error or Fatal entry is also collected and
emailed to `Alerts:Emails`: the first error waits `CollectSeconds` for related ones, then one email lists them (India
time, where, message, exception), at most one email per `MinMinutesBetween`. Alerts go straight through the email
provider, not the database queue, so they still arrive when the database is the problem; a failed alert is only logged
as a warning.

## Errors in three languages

Every refusal is problem+json with a stable `code`, its values in `args`, and a `title` in the language of the
request's `Accept-Language` header (the app sends its language on every call):

```json
{ "status": 429, "code": "otp_wait", "args": { "seconds": 30 }, "title": "కొత్త OTP అడగడానికి ముందు 30 సెకన్లు ఆగండి" }
```

Rules return an `ApiError` (`Domain/Common`), controllers answer with `this.Fail(status, "code", ("name", value))`, and
the words live in one catalogue: `Infrastructure/Errors/ErrorText.cs` (English, Telugu, Hindi). A test scans the API for
every code it uses and fails if one has no words, and another renders every code in all three languages.

## Dates and times

Every DateTime is stored and sent as UTC: an EF convention (`Persistence/UtcDateTimes.cs`) marks values UTC when read
back, so JSON always ends in `Z`, and the app shows local time (`core/api/api_dates.dart`). Slot times and booking dates
are India times (`DateOnly`, `TimeOnly`).

## Photos

Every upload goes through `shrinkPhoto` (`mobile/lib/core/photo_compress.dart`): on a phone the photo is re-encoded as
JPEG and stepped down in size and quality until it is under 400 KB, and EXIF data (including GPS) is dropped. In a
browser the picker's own resize (1600 px, quality 70) is used. The server still accepts up to 8 MB.

## Terms, privacy and problem reports

- **Pages**: `GET /legal/terms` and `/legal/privacy` (English text, with a Telugu or Hindi summary on top). They describe
  what the app really collects and why, and are a **draft for a lawyer to review before launch**. Raise
  `LegalPages.Version` whenever either text changes.
- **Consent**: the login answer and `GET /users/me` say `termsAccepted`; until then the app shows the consent screen
  (what is used and why, links to both pages, "I agree") and records it with `POST /users/me/consent { version }`
  (`User.TermsVersion`, `TermsAcceptedAt`). An old version is refused (409), so nobody accepts words they were not shown.
  Already signed-in users are asked on their next visit to the home screen.
- **Reports**: `POST /api/v1/reports { category, message, bookingId? }` (10–1000 characters, at most 10 a day, a booking
  only if the user is its farmer or host), `GET /reports/mine`; admins `GET /ops/reports?status=Open|Resolved` and
  `POST /ops/reports/{id}/resolve { resolution }`. Categories: someone did not come, the space, payment or fee,
  behaviour or safety, the app, something else.

Migration: `RemindersReportsConsent`.

## Still needed

- **Google Maps**: add `MAPS_API_KEY=...` to `mobile/android/local.properties` (map pins instead of coordinates)
- **Push alerts**: create a Firebase project, add `mobile/android/app/google-services.json`, then call `Firebase.initializeApp()` in `main.dart`
- **Real SMS**: Kinichit.Communication is already in place (`ISmsSender`, `Sms` settings); send the OTP through it with MSG91 and a DLT-registered template instead of `DevOtpService`
- **Android emulator or phone**: install Android Studio for the emulator, or enable USB debugging on a phone
- `permission_handler` is held at 12.x and `pinput` at 6.x until they work with this Flutter/AGP version
