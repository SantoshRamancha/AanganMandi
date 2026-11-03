import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_screen.dart';
import '../../features/farmer/verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/host/host_bookings_screen.dart';
import '../../features/host/space_detail_screen.dart';
import '../../features/host/space_form_screen.dart';
import '../../features/onboarding/language_screen.dart';
import '../../features/onboarding/role_screen.dart';
import '../../features/ops/farmer_review_screen.dart';
import '../../features/ops/space_review_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/trips/space_search_screen.dart';
import '../../features/trips/trip_detail_screen.dart';
import '../../features/trips/trip_form_screen.dart';
import '../storage/prefs.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Prefs.languageCode == null
        ? '/language'
        : Prefs.role == null
            ? '/login'
            : '/home',
    routes: [
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/login', builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        // A browser refresh on /otp loses the phone number: go back to login.
        redirect: (_, state) => state.extra is OtpArgs ? null : '/login',
        builder: (_, state) {
          final args = state.extra! as OtpArgs;
          return OtpScreen(phone: args.phone, devCode: args.devCode);
        },
      ),
      GoRoute(path: '/role', builder: (_, _) => const RoleScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/farmer/verify', builder: (_, _) => const VerificationScreen()),
      // Trips and space booking (verified farmers). "new" must come before ":id".
      GoRoute(path: '/farmer/trips/new', builder: (_, _) => const TripFormScreen()),
      GoRoute(path: '/farmer/trips/:id', builder: (_, state) => TripDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/farmer/trips/:id/edit', builder: (_, state) => TripFormScreen(tripId: state.pathParameters['id'])),
      GoRoute(path: '/farmer/trips/:id/spaces', builder: (_, state) => SpaceSearchScreen(tripId: state.pathParameters['id']!)),
      GoRoute(
        path: '/host/bookings',
        builder: (_, state) => HostBookingsScreen(initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0),
      ),
      GoRoute(path: '/host/spaces/new', builder: (_, _) => const SpaceFormScreen()),
      GoRoute(path: '/host/spaces/:id', builder: (_, state) => SpaceDetailScreen(id: state.pathParameters['id']!)),
      // Staff (Verifier / Admin) review screens; the queues live in the operations home.
      GoRoute(path: '/ops/farmers/:id', builder: (_, state) => FarmerReviewScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/ops/spaces/:id', builder: (_, state) => SpaceReviewScreen(id: state.pathParameters['id']!)),
    ],
  );
});
