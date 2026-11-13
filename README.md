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

## Still needed

- **Google Maps**: add `MAPS_API_KEY=...` to `mobile/android/local.properties` (map pins instead of coordinates)
- **Push alerts**: create a Firebase project, add `mobile/android/app/google-services.json`, then call `Firebase.initializeApp()` in `main.dart`
- **Real SMS**: Kinichit.Communication is already in place (`ISmsSender`, `Sms` settings); send the OTP through it with MSG91 and a DLT-registered template instead of `DevOtpService`
- **Android emulator or phone**: install Android Studio for the emulator, or enable USB debugging on a phone
- `permission_handler` is held at 12.x and `pinput` at 6.x until they work with this Flutter/AGP version
