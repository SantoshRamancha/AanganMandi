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

Not built yet: in-app payment, buyer alerts and produce browsing, maps, push notifications (hosts and farmers see new requests and answers when they open the app).

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

In VS Code, open the `C:\Aangan_Mandi` folder, Run and Debug, pick **"Everything: API + Flutter (Chrome)"**, press F5.
For the Android emulator or a phone, pick **"API + Flutter app (phone / emulator)"**.

Or in two terminals:

```bash
dotnet run --project backend/src/AanganMandi.Api --launch-profile http
```
```bash
cd mobile && flutter run -d chrome
```

| What | URL |
|---|---|
| API + Swagger | http://localhost:5080/swagger |
| App on Android emulator | calls `http://10.0.2.2:5080/api/v1` |
| App on a phone on Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<PC-IP>:5080/api/v1` |

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

## Still needed

- **Google Maps**: add `MAPS_API_KEY=...` to `mobile/android/local.properties` (map pins instead of coordinates)
- **Push alerts**: create a Firebase project, add `mobile/android/app/google-services.json`, then call `Firebase.initializeApp()` in `main.dart`
- **Real SMS**: replace `DevOtpService` with a DLT-registered SMS gateway
- **Android emulator or phone**: install Android Studio for the emulator, or enable USB debugging on a phone
- **Production storage**: replace `LocalFileStorage` with Azure Blob private containers
- `permission_handler` is held at 12.x and `pinput` at 6.x until they work with this Flutter/AGP version
