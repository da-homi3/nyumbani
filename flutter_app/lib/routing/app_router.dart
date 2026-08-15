import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/features/admin/presentation/admin_advertise_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_announcements_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_create_listing_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_create_provider_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_home_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_identity_verifications_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_listings_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_pending_providers_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_pm_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_portal_applications_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_promo_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_revenue_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_scam_reports_page.dart';
import 'package:nyumbasearch/features/admin/presentation/admin_verifications_page.dart';
import 'package:nyumbasearch/features/auth/presentation/auth_pending_page.dart';
import 'package:nyumbasearch/features/auth/presentation/login_page.dart';
import 'package:nyumbasearch/features/auth/presentation/password_reset_page.dart';
import 'package:nyumbasearch/features/auth/presentation/signup_page.dart';
import 'package:nyumbasearch/features/auth/presentation/oauth_callback_page.dart';
import 'package:nyumbasearch/features/auth/presentation/splash_page.dart';
import 'package:nyumbasearch/features/caretaker/presentation/caretaker_dashboard_page.dart';
import 'package:nyumbasearch/features/caretaker/presentation/caretaker_login_page.dart';
import 'package:nyumbasearch/features/compare/presentation/compare_page.dart';
import 'package:nyumbasearch/features/content/presentation/advertise_page.dart';
import 'package:nyumbasearch/features/content/presentation/contact_page.dart';
import 'package:nyumbasearch/features/content/presentation/site_content_page.dart';
import 'package:nyumbasearch/features/favorites/presentation/saved_page.dart';
import 'package:nyumbasearch/features/home/presentation/home_page.dart';
import 'package:nyumbasearch/features/home/presentation/home_shell.dart';
import 'package:nyumbasearch/features/billing/presentation/billing_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/boost_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/caretakers_manage_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/create_listing_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/edit_listing_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/integrations_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/landlord_analytics_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/landlord_dashboard_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/landlord_plan_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/lead_packs_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/listing_import_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/my_listings_page.dart';
import 'package:nyumbasearch/features/landlord/presentation/payout_settings_page.dart';
import 'package:nyumbasearch/features/maps/presentation/map_page.dart';
import 'package:nyumbasearch/features/messages/presentation/message_thread_page.dart';
import 'package:nyumbasearch/features/messages/presentation/messages_page.dart';
import 'package:nyumbasearch/features/notifications/presentation/notifications_page.dart';
import 'package:nyumbasearch/features/portal/presentation/org_team_page.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_dashboard_page.dart';
import 'package:nyumbasearch/features/portal/presentation/portal_home_page.dart';
import 'package:nyumbasearch/features/profile/presentation/settings_page.dart';
import 'package:nyumbasearch/features/properties/presentation/property_detail_page.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_create_page.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_list_page.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_property_page.dart';
import 'package:nyumbasearch/features/property_management/presentation/pm_subscribe_page.dart';
import 'package:nyumbasearch/features/providers/presentation/provider_detail_page.dart';
import 'package:nyumbasearch/features/providers/presentation/provider_me_page.dart';
import 'package:nyumbasearch/features/providers/presentation/provider_register_page.dart';
import 'package:nyumbasearch/features/providers/presentation/providers_page.dart';
import 'package:nyumbasearch/features/referrals/presentation/referrals_page.dart';
import 'package:nyumbasearch/features/reviews/presentation/leave_review_page.dart';
import 'package:nyumbasearch/features/search/presentation/saved_searches_page.dart';
import 'package:nyumbasearch/features/search/presentation/search_page.dart';
import 'package:nyumbasearch/features/subscriptions/presentation/plus_page.dart';
import 'package:nyumbasearch/features/tenants/presentation/complaints_page.dart';
import 'package:nyumbasearch/features/tenants/presentation/maintenance_page.dart';
import 'package:nyumbasearch/features/tenants/presentation/rent_page.dart';
import 'package:nyumbasearch/features/tenants/presentation/tenant_invite_page.dart';
import 'package:nyumbasearch/features/verification/presentation/verify_request_page.dart';
import 'package:nyumbasearch/routing/deep_links.dart';
import 'package:nyumbasearch/routing/page_transitions.dart';

final _rootKey = GlobalKey<NavigatorState>();

bool _isOAuthCallback(Uri uri) {
  if (uri.host == 'login-callback') return true;
  if (uri.path == '/login-callback' || uri.path.endsWith('/login-callback')) {
    return true;
  }
  return uri.toString().contains('login-callback');
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final uri = state.uri;

      // Custom-scheme OAuth return → dedicated callback route (session exchange).
      if (_isOAuthCallback(uri) && state.matchedLocation != '/login-callback') {
        return '/login-callback';
      }

      // Normalize App Links / full https URIs.
      if (uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http')) {
        final mapped = DeepLinks.toAppLocation(uri);
        if (mapped != null && mapped != state.matchedLocation) {
          return mapped;
        }
      }

      final path = state.uri.path;
      if (path.startsWith('/tenant/property/')) {
        final parts = path.split('/').where((s) => s.isNotEmpty).toList();
        if (parts.length >= 3) return '/property/${parts[2]}';
      }
      return null;
    },
    routes: [
      fadeRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      fadeRoute(path: '/login', builder: (context, state) => const LoginPage()),
      fadeRoute(
        path: '/login-callback',
        builder: (context, state) => OAuthCallbackPage(uri: state.uri),
      ),
      fadeRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      fadeRoute(
        path: '/auth/pending',
        builder: (context, state) => const AuthPendingPage(),
      ),
      fadeRoute(
        path: '/auth/reset',
        builder: (context, state) => PasswordResetPage(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      fadeRoute(
        path: '/referrals',
        builder: (context, state) => const ReferralsPage(),
      ),
      fadeRoute(
        path: '/compare',
        builder: (context, state) => const ComparePage(),
      ),
      fadeRoute(
        path: '/saved-searches',
        builder: (context, state) => const SavedSearchesPage(),
      ),
      
      // Agency / manager aliases → shared landlord & PM surfaces (portal denseness).
      GoRoute(path: '/agency/listings', redirect: (c, s) => '/landlord/listings'),
      GoRoute(path: '/agency/analytics', redirect: (c, s) => '/landlord/analytics'),
      GoRoute(path: '/agency/pm', redirect: (c, s) => '/pm'),
      GoRoute(path: '/agency/billing', redirect: (c, s) => '/billing'),
      GoRoute(path: '/agency/payouts', redirect: (c, s) => '/landlord/payouts'),
      GoRoute(path: '/agency/messages', redirect: (c, s) => '/messages'),
      GoRoute(path: '/manager/listings', redirect: (c, s) => '/landlord/listings'),
      GoRoute(path: '/manager/analytics', redirect: (c, s) => '/landlord/analytics'),
      GoRoute(path: '/manager/pm', redirect: (c, s) => '/pm'),
      GoRoute(path: '/manager/billing', redirect: (c, s) => '/billing'),
      GoRoute(path: '/manager/payouts', redirect: (c, s) => '/landlord/payouts'),
      GoRoute(path: '/manager/messages', redirect: (c, s) => '/messages'),

      fadeRoute(
        path: '/agency',
        builder: (context, state) => const AgencyDashboardPage(),
      ),
      fadeRoute(
        path: '/agency/team',
        builder: (context, state) => const OrgTeamPage(portalLabel: 'Agency', portal: 'agency'),
      ),
      fadeRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboardPage(),
      ),
      fadeRoute(
        path: '/manager/team',
        builder: (context, state) => const OrgTeamPage(portalLabel: 'Manager', portal: 'manager'),
      ),
      fadeRoute(
        path: '/property/:id',
        builder: (context, state) => PropertyDetailPage(
          propertyId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'review',
            builder: (context, state) => LeaveReviewPage(
              propertyId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/tenant/property/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          return id == null ? '/home' : '/property/$id';
        },
      ),
      fadeRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      fadeRoute(
        path: '/messages/:id',
        builder: (context, state) => MessageThreadPage(
          threadId: state.pathParameters['id']!,
        ),
      ),
      fadeRoute(
        path: '/plus',
        builder: (context, state) => const PlusPage(),
      ),
      fadeRoute(
        path: '/saved',
        builder: (context, state) => const SavedPage(),
      ),
      fadeRoute(
        path: '/profile',
        builder: (context, state) => const SettingsPage(),
      ),
      fadeRoute(
        path: '/settings',
        builder: (context, state) => SettingsPage(
          initialTab: state.uri.queryParameters['tab'] ?? 'profile',
        ),
      ),
      fadeRoute(
        path: '/tenant/invite/:token',
        builder: (context, state) => TenantInvitePage(
          token: state.pathParameters['token']!,
        ),
      ),
      fadeRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenancePage(),
      ),
      fadeRoute(
        path: '/complaints',
        builder: (context, state) => const ComplaintsPage(),
      ),
      fadeRoute(
        path: '/verify',
        builder: (context, state) => const VerifyRequestPage(),
      ),
      fadeRoute(
        path: '/verify/:id',
        builder: (context, state) => VerifyStatusPage(
          requestId: state.pathParameters['id']!,
        ),
      ),
      fadeRoute(
        path: '/portals',
        builder: (context, state) => const PortalHomePage(),
      ),
      fadeRoute(
        path: '/landlord',
        builder: (context, state) => const LandlordDashboardPage(),
      ),
      fadeRoute(
        path: '/landlord/analytics',
        builder: (context, state) => const LandlordAnalyticsPage(),
      ),
      fadeRoute(
        path: '/landlord/plan',
        builder: (context, state) => const LandlordPlanPage(),
      ),
      fadeRoute(
        path: '/landlord/boost',
        builder: (context, state) => BoostPage(
          initialPropertyId: state.uri.queryParameters['propertyId'],
        ),
      ),
      fadeRoute(
        path: '/landlord/caretakers',
        builder: (context, state) => const CaretakersManagePage(),
      ),
      fadeRoute(
        path: '/landlord/payouts',
        builder: (context, state) => const PayoutSettingsPage(),
      ),
      fadeRoute(
        path: '/landlord/leads',
        builder: (context, state) => const LeadPacksPage(),
      ),
      fadeRoute(
        path: '/billing',
        builder: (context, state) => const BillingPage(),
      ),
      fadeRoute(
        path: '/landlord/listings',
        builder: (context, state) => const MyListingsPage(),
      ),
      fadeRoute(
        path: '/landlord/listings/new',
        builder: (context, state) => const CreateListingPage(),
      ),
      fadeRoute(
        path: '/landlord/listings/:id/edit',
        builder: (context, state) => EditListingPage(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      fadeRoute(
        path: '/pm',
        builder: (context, state) => const PmListPage(),
      ),
      fadeRoute(
        path: '/pm/new',
        builder: (context, state) => const PmCreatePage(),
      ),
      fadeRoute(
        path: '/pm/subscribe',
        builder: (context, state) => const PmSubscribePage(),
      ),
      fadeRoute(
        path: '/pm/:id',
        builder: (context, state) => PmPropertyPage(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      fadeRoute(
        path: '/services',
        builder: (context, state) => const ProvidersPage(),
      ),
      fadeRoute(
        path: '/services/register',
        builder: (context, state) => const ProviderRegisterPage(),
      ),
      fadeRoute(
        path: '/services/me',
        builder: (context, state) => const ProviderMePage(),
      ),
      fadeRoute(
        path: '/services/:id',
        builder: (context, state) => ProviderDetailPage(
          providerId: state.pathParameters['id']!,
        ),
      ),
      fadeRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomePage(),
      ),
      fadeRoute(
        path: '/admin/verifications',
        builder: (context, state) => const AdminVerificationsPage(),
      ),
      fadeRoute(
        path: '/admin/identity-verifications',
        builder: (context, state) => const AdminIdentityVerificationsPage(),
      ),
      fadeRoute(
        path: '/admin/applications',
        builder: (context, state) => const AdminPortalApplicationsPage(),
      ),
      fadeRoute(
        path: '/admin/providers',
        builder: (context, state) => const AdminPendingProvidersPage(),
      ),
      fadeRoute(
        path: '/admin/providers/new',
        builder: (context, state) => const AdminCreateProviderPage(),
      ),
      fadeRoute(
        path: '/admin/scams',
        builder: (context, state) => const AdminScamReportsPage(),
      ),
      fadeRoute(
        path: '/admin/listings',
        builder: (context, state) => const AdminListingsPage(),
      ),
      fadeRoute(
        path: '/admin/listings/new',
        builder: (context, state) => const AdminCreateListingPage(),
      ),
      fadeRoute(
        path: '/admin/pm',
        builder: (context, state) => const AdminPmPage(),
      ),
      fadeRoute(
        path: '/admin/revenue',
        builder: (context, state) => const AdminRevenuePage(),
      ),
      fadeRoute(
        path: '/admin/announcements',
        builder: (context, state) => const AdminAnnouncementsPage(),
      ),
      fadeRoute(
        path: '/admin/promo',
        builder: (context, state) => const AdminPromoPage(),
      ),
      fadeRoute(
        path: '/admin/advertise',
        builder: (context, state) => const AdminAdvertisePage(),
      ),
      fadeRoute(
        path: '/landlord/import',
        builder: (context, state) => const ListingImportPage(),
      ),
      fadeRoute(
        path: '/landlord/integrations',
        builder: (context, state) => const IntegrationsPage(),
      ),
      fadeRoute(
        path: '/agency/import',
        builder: (context, state) => const ListingImportPage(),
      ),
      fadeRoute(
        path: '/agency/integrations',
        builder: (context, state) => const IntegrationsPage(),
      ),
      fadeRoute(
        path: '/manager/import',
        builder: (context, state) => const ListingImportPage(),
      ),
      fadeRoute(
        path: '/manager/integrations',
        builder: (context, state) => const IntegrationsPage(),
      ),
      fadeRoute(
        path: '/contact',
        builder: (context, state) => const ContactPage(),
      ),
      fadeRoute(
        path: '/advertise',
        builder: (context, state) => const AdvertisePage(),
      ),
      fadeRoute(
        path: '/about',
        builder: (context, state) =>
            const SiteContentPage(title: 'About', path: '/about'),
      ),
      fadeRoute(
        path: '/privacy',
        builder: (context, state) =>
            const SiteContentPage(title: 'Privacy', path: '/privacy'),
      ),
      fadeRoute(
        path: '/terms-of-service',
        builder: (context, state) => const SiteContentPage(
          title: 'Terms of service',
          path: '/terms-of-service',
        ),
      ),
      fadeRoute(
        path: '/cookie-policy',
        builder: (context, state) =>
            const SiteContentPage(title: 'Cookie policy', path: '/cookie-policy'),
      ),
      fadeRoute(
        path: '/refund-policy',
        builder: (context, state) =>
            const SiteContentPage(title: 'Refund policy', path: '/refund-policy'),
      ),
      fadeRoute(
        path: '/data-deletion',
        builder: (context, state) =>
            const SiteContentPage(title: 'Data deletion', path: '/data-deletion'),
      ),
      fadeRoute(
        path: '/acceptable-use-policy',
        builder: (context, state) => const SiteContentPage(
          title: 'Acceptable use',
          path: '/acceptable-use-policy',
        ),
      ),
      fadeRoute(
        path: '/landlord-agreement',
        builder: (context, state) => const SiteContentPage(
          title: 'Landlord agreement',
          path: '/landlord-agreement',
        ),
      ),
      fadeRoute(
        path: '/finance',
        builder: (context, state) =>
            const SiteContentPage(title: 'Finance', path: '/finance'),
      ),
      fadeRoute(
        path: '/insurance',
        builder: (context, state) =>
            const SiteContentPage(title: 'Insurance', path: '/insurance'),
      ),
      fadeRoute(
        path: '/reports',
        builder: (context, state) =>
            const SiteContentPage(title: 'Reports', path: '/reports'),
      ),
      fadeRoute(
        path: '/whatsapp',
        builder: (context, state) =>
            const SiteContentPage(title: 'WhatsApp', path: '/whatsapp'),
      ),
      fadeRoute(
        path: '/caretaker/login',
        builder: (context, state) => const CaretakerLoginPage(),
      ),
      fadeRoute(
        path: '/caretaker/dashboard',
        builder: (context, state) => const CaretakerDashboardPage(),
      ),
      GoRoute(
        path: '/caretaker',
        redirect: (context, state) => '/caretaker/login',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (context, state) => const MapPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/rent', builder: (context, state) => const RentPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/messages', builder: (context, state) => const MessagesPage()),
            ],
          ),
        ],
      ),
    ],
  );
});
