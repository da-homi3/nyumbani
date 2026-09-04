/// Maps website / App Link URLs onto in-app GoRouter locations.
class DeepLinks {
  const DeepLinks._();

  static const hosts = {'nyumbasearch.com', 'www.nyumbasearch.com'};

  /// Returns an in-app path, or null if the URI is not handled natively.
  static String? toAppLocation(Uri uri) {
    final host = uri.host.toLowerCase();
    final isHttpsHost = (uri.scheme == 'https' || uri.scheme == 'http') && hosts.contains(host);
    final isCustomScheme = uri.scheme == 'ke.co.nyumbasearch.app';

    if (!isHttpsHost && !isCustomScheme) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/home';

    // https://nyumbasearch.com/tenant/property/:id
    if (segments.length >= 3 &&
        segments[0] == 'tenant' &&
        segments[1] == 'property') {
      return '/property/${segments[2]}';
    }

    if (segments.length >= 3 &&
        segments[0] == 'tenant' &&
        segments[1] == 'provider') {
      return '/provider/${segments[2]}';
    }

    if (segments.length >= 2 &&
        segments[0] == 'tenant' &&
        segments[1] == 'applications') {
      return '/applications';
    }

    if (segments.length >= 2 &&
        segments[0] == 'tenant' &&
        segments[1] == 'viewings') {
      return '/viewings';
    }

    // Alias if we ever publish shorter links
    if (segments.length >= 2 && segments[0] == 'property') {
      return '/property/${segments[1]}';
    }

    if (segments.first == 'tenant' && segments.length == 1) return '/home';
    if (segments.first == 'search') return '/search';
    if (segments.first == 'map') return '/map';
    if (segments.first == 'plus') return '/plus';
    if (segments.first == 'referrals') return '/referrals';
    if (segments.first == 'compare') return '/compare';
    if (segments.first == 'saved-searches') return '/saved-searches';
    if (segments.first == 'pm' || segments.first == 'property-management') {
      return '/pm';
    }
    if (segments.first == 'messages') {
      if (segments.length >= 2) return '/messages/${segments[1]}';
      return '/messages';
    }
    if (segments.first == 'notifications') return '/notifications';
    if (segments.first == 'portals') return '/portals';
    if (segments.first == 'billing') return '/billing';

    // https://nyumbasearch.com/tenant/invite/:token
    if (segments.length >= 3 &&
        segments[0] == 'tenant' &&
        segments[1] == 'invite') {
      return '/tenant/invite/${segments[2]}';
    }

    if (segments.first == 'tenant') {
      if (segments.length >= 2 && segments[1] == 'rent') return '/rent';
      if (segments.length >= 2 && segments[1] == 'maintenance') {
        return '/maintenance';
      }
      if (segments.length >= 2 && segments[1] == 'complaints') {
        return '/complaints';
      }
      if (segments.length >= 2 && segments[1] == 'saved') return '/saved';
    }

    if (segments.first == 'auth') {
      if (segments.length >= 2 && segments[1] == 'pending') {
        return '/auth/pending';
      }
      if (segments.length >= 2 && segments[1] == 'reset') {
        return '/auth/reset';
      }
      return '/login';
    }

    if (segments.first == 'verify') {
      if (segments.length >= 3 && segments[1] == 'status') {
        return '/verify/${segments[2]}';
      }
      if (segments.length >= 2 && segments[1] != 'request') {
        return '/verify/${segments[1]}';
      }
      return '/verify';
    }

    if (segments.first == 'services') {
      if (segments.length >= 2) {
        if (segments[1] == 'register') return '/services/register';
        if (segments[1] == 'me' || segments[1] == 'dashboard') {
          return '/services/me';
        }
        if (segments[1] == 'provider' && segments.length >= 3) {
          return '/services/${segments[2]}';
        }
        return '/services/${segments[1]}';
      }
      return '/services';
    }

    if (segments.first == 'caretaker') {
      if (segments.length >= 2 && segments[1] == 'dashboard') {
        return '/caretaker/dashboard';
      }
      return '/caretaker/login';
    }

    if (segments.first == 'agency') {
      if (segments.length >= 2 && segments[1] == 'team') return '/agency/team';
      return '/agency';
    }

    if (segments.first == 'manager') {
      if (segments.length >= 2 && segments[1] == 'team') return '/manager/team';
      return '/manager';
    }

    if (segments.first == 'admin') {
      if (segments.length >= 2) {
        return switch (segments[1]) {
          'listings' => '/admin/listings',
          'providers' => '/admin/providers',
          'applications' => '/admin/applications',
          'scams' => '/admin/scams',
          'pm' => '/admin/pm',
          'verifications' => '/admin/verifications',
          _ => '/admin',
        };
      }
      return '/admin';
    }

    if (segments.first == 'landlord') {
      if (segments.length >= 2 && segments[1] == 'boost') {
        final propertyId = uri.queryParameters['propertyId'];
        if (propertyId != null && propertyId.isNotEmpty) {
          return '/landlord/boost?propertyId=$propertyId';
        }
        return '/landlord/boost';
      }
      if (segments.length >= 2 &&
          (segments[1] == 'checkout' || segments[1] == 'plan')) {
        return '/landlord/plan';
      }
      if (segments.length >= 2 && segments[1] == 'analytics') {
        return '/landlord/analytics';
      }
      if (segments.length >= 2 && segments[1] == 'leads') {
        return '/landlord/leads';
      }
      if (segments.length >= 2 && segments[1] == 'applications') {
        return '/landlord/applications';
      }
      if (segments.length >= 2 && segments[1] == 'viewings') {
        return '/landlord/viewings';
      }
      if (segments.length >= 2 && segments[1] == 'properties') {
        if (segments.length >= 3 && segments[2] == 'new') {
          return '/landlord/listings/new';
        }
        return '/landlord/listings';
      }
      if (segments.length >= 2 &&
          (segments[1] == 'manage' || segments[1] == 'pm')) {
        return '/pm';
      }
      if (segments.length >= 2 && segments[1] == 'payouts') {
        return '/landlord/payouts';
      }
      if (segments.length >= 2 && segments[1] == 'caretakers') {
        return '/landlord/caretakers';
      }
      if (segments.length == 1 || segments[1] == 'dashboard') {
        return '/landlord';
      }
    }

    return null;
  }

  static Uri? portalUriForRole(String role, {String baseUrl = 'https://nyumbasearch.com'}) {
    final path = switch (role.toLowerCase()) {
      'landlord' => '/landlord',
      'agency' => '/agency',
      'manager' => '/manager',
      'caretaker' => '/caretaker/dashboard',
      'admin' => '/admin',
      'provider' => '/services',
      _ => null,
    };
    if (path == null) return null;
    return Uri.parse('$baseUrl$path');
  }

  static String labelForRole(String role) {
    return switch (role.toLowerCase()) {
      'landlord' => 'Landlord',
      'agency' => 'Agency',
      'manager' => 'Manager',
      'caretaker' => 'Caretaker',
      'admin' => 'Admin',
      'provider' => 'Services',
      'tenant' => 'Tenant',
      _ => role,
    };
  }
}
