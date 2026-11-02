import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_screen.dart';
import '../../features/farmer/verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/host/space_detail_screen.dart';
import '../../features/host/space_form_screen.dart';
import '../../features/onboarding/language_screen.dart';
import '../../features/onboarding/role_screen.dart';
import '../../features/ops/farmer_review_screen.dart';
import '../../features/ops/space_review_screen.dart';
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
      GoRoute(path: '/farmer/verify', builder: (_, _) => const VerificationScreen()),
      GoRoute(path: '/host/spaces/new', builder: (_, _) => const SpaceFormScreen()),
      GoRoute(path: '/host/spaces/:id', builder: (_, state) => SpaceDetailScreen(id: state.pathParameters['id']!)),
      // Staff (Verifier / Admin) review screens; the queues live in the operations home.
      GoRoute(path: '/ops/farmers/:id', builder: (_, state) => FarmerReviewScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/ops/spaces/:id', builder: (_, state) => SpaceReviewScreen(id: state.pathParameters['id']!)),
    ],
  );
});
