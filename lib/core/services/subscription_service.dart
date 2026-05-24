import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_routes.dart';
import '../constants/feature_flags.dart';
import 'supabase_service.dart';

/// Result of a StoreKit / Play purchase attempt.
class SubscriptionPurchaseOutcome {
  const SubscriptionPurchaseOutcome._({
    required this.success,
    this.cancelled = false,
    this.message,
  });

  const SubscriptionPurchaseOutcome.success()
      : this._(success: true);

  const SubscriptionPurchaseOutcome.cancelled()
      : this._(success: false, cancelled: true);

  const SubscriptionPurchaseOutcome.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final bool cancelled;
  final String? message;
}

/// Monthly / annual plans resolved from RevenueCat for the paywall.
class PaywallPlans {
  const PaywallPlans({
    this.monthlyPackage,
    this.annualPackage,
    this.monthlyProduct,
    this.annualProduct,
    this.monthlyPrice = '\$4.99',
    this.annualMonthlyPrice = '\$2.50',
    this.annualYearlyPrice = '\$29.99',
    this.loadError,
  });

  final Package? monthlyPackage;
  final Package? annualPackage;
  final StoreProduct? monthlyProduct;
  final StoreProduct? annualProduct;
  final String monthlyPrice;
  final String annualMonthlyPrice;
  final String annualYearlyPrice;
  final String? loadError;

  bool get hasMonthly => monthlyPackage != null || monthlyProduct != null;
  bool get hasAnnual => annualPackage != null || annualProduct != null;
  bool get canPurchase => hasMonthly || hasAnnual;
}

/// Subscription and session gate service (RevenueCat + free tier limit).
class SubscriptionService {
  const SubscriptionService();

  static bool _configured = false;

  /// Whether [initialise] completed successfully.
  static bool get isConfigured => _configured;

  static int get freeSessionLimit => FeatureFlags.subscriptionFreeSessionLimit;
  static const String _entitlementId = 'Thankful: AI voice Journal Pro';

  static String get _offeringId {
    final fromEnv = dotenv.env['REVENUECAT_OFFERING_ID']?.trim() ?? '';
    return fromEnv.isNotEmpty ? fromEnv : 'ThankfulDefault';
  }

  // DEV BYPASS — remove before App Store submission
  static const List<String> _devBypassUserIds = [
    '7280bf48-fddf-4630-9466-1b7cc97f8234',
  ];

  static bool _hasDevBypass(String userId) =>
      FeatureFlags.subscriptionDevBypass &&
      _devBypassUserIds.contains(userId);

  static bool _hasPremiumEntitlement(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.containsKey(_entitlementId)) return true;
    if (active.isNotEmpty) {
      print(
        '[RevenueCat] Entitlement "$_entitlementId" not found; active: '
        '${active.keys.toList()}',
      );
      return true;
    }
    return false;
  }

  static String? _revenueCatApiKey() {
    final primary = dotenv.env['REVENUECAT_API_KEY']?.trim() ?? '';
    if (primary.isNotEmpty) return primary;
    return dotenv.env['REVENUECAT_APPLE_KEY']?.trim();
  }

  /// Call once at app startup in main.dart after dotenv.load()
  static Future<void> initialise() async {
    _configured = false;
    final apiKey = _revenueCatApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      print(
        '[RevenueCat] REVENUECAT_API_KEY missing — skipping init '
        '(add appl_… key to .env)',
      );
      return;
    }
    if (!apiKey.startsWith('appl_') && !apiKey.startsWith('goog_')) {
      print(
        '[RevenueCat] Warning: API key should start with appl_ (iOS) or goog_ (Android)',
      );
    }
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _configured = await Purchases.isConfigured;
      print('[RevenueCat] Initialised (configured=$_configured)');

      // Identify user with Supabase user ID so RevenueCat links purchases to user
      if (SupabaseService.isInitialized) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Purchases.logIn(userId);
          print('[RevenueCat] Logged in user: $userId');
        }
      }
    } catch (e) {
      _configured = false;
      print('[RevenueCat] initialise error: $e');
    }
  }

  /// True when RevenueCat SDK is ready to present the App Store purchase sheet.
  static Future<bool> ensurePurchasesReady() async {
    if (_configured) return true;
    try {
      _configured = await Purchases.isConfigured;
    } catch (_) {
      _configured = false;
    }
    return _configured;
  }

  /// Returns true if user has active premium entitlement (includes free trial).
  Future<bool> isSubscribed() async {
    if (FeatureFlags.subscriptionIgnoreRevenueCatEntitlement) {
      print('[RevenueCat] isSubscribed: ignored (subscriptionIgnoreRevenueCatEntitlement)');
      return false;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final activeKeys = info.entitlements.active.keys.toList();
      final active = _hasPremiumEntitlement(info);
      print(
        '[RevenueCat] isSubscribed: $active | active entitlements: $activeKeys | '
        'looking for: $_entitlementId',
      );
      return active;
    } catch (e) {
      print('[RevenueCat] isSubscribed error: $e — defaulting to false');
      return false;
    }
  }

  /// Navigate to convo or paywall depending on [canStartSession].
  static Future<void> navigateToSessionOrPaywall(
    BuildContext context, {
    bool paywallOnboardingProgress = false,
  }) async {
    final canStart = await const SubscriptionService().canStartSession();
    if (!context.mounted) return;
    if (!canStart) {
      print('[Subscription] Blocked — navigating to paywall');
      context.go(
        AppRoutes.paywall,
        extra: paywallOnboardingProgress ? true : null,
      );
      return;
    }
    context.go(AppRoutes.onboardingConvo);
  }

  /// Fetch the default offering from RevenueCat.
  Future<Offering?> getOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return _pickOffering(offerings);
    } catch (e) {
      print('[RevenueCat] getOffering error: $e');
      return null;
    }
  }

  /// Resolves paywall packages — offerings first, then optional .env product IDs.
  Future<PaywallPlans> loadPaywallPlans() async {
    if (!await ensurePurchasesReady()) {
      return const PaywallPlans(
        loadError: 'RevenueCat is not configured. Check REVENUECAT_API_KEY in .env.',
      );
    }

    try {
      final offerings = await Purchases.getOfferings();
      for (final id in offerings.all.keys) {
        final o = offerings.all[id]!;
        print(
          '[RevenueCat] Offering "$id": ${o.availablePackages.length} package(s)',
        );
      }

      final offering = _pickOffering(offerings);
      if (offering != null && offering.availablePackages.isNotEmpty) {
        final monthly = _pickPackage(offering.availablePackages, annual: false);
        final annual = _pickPackage(offering.availablePackages, annual: true);
        print(
          '[RevenueCat] Resolved from offering "${offering.identifier}" — '
          'monthly=${monthly?.identifier} annual=${annual?.identifier}',
        );
        return _plansFromPackages(monthly: monthly, annual: annual);
      }

      print(
        '[RevenueCat] No packages in offerings — trying direct product IDs from .env',
      );
      final fromProducts = await _plansFromEnvProductIds();
      if (fromProducts.canPurchase) return fromProducts;

      final offeringId = offering?.identifier ?? '(none)';
      return PaywallPlans(
        loadError:
            'No subscription products loaded. In RevenueCat, set offering '
            '"$_offeringId" (or Current) with monthly + annual packages linked '
            'to App Store Connect. Offering found: $offeringId with '
            '${offering?.availablePackages.length ?? 0} package(s). '
            'Or add REVENUECAT_MONTHLY_PRODUCT_ID and REVENUECAT_ANNUAL_PRODUCT_ID to .env.',
      );
    } catch (e) {
      print('[RevenueCat] loadPaywallPlans error: $e');
      return PaywallPlans(loadError: 'Could not load plans: $e');
    }
  }

  static Offering? _pickOffering(Offerings offerings) {
    final preferred = offerings.getOffering(_offeringId);
    if (preferred != null && preferred.availablePackages.isNotEmpty) {
      return preferred;
    }
    final current = offerings.current;
    if (current != null && current.availablePackages.isNotEmpty) {
      print('[RevenueCat] Using current offering "${current.identifier}"');
      return current;
    }
    if (preferred != null) return preferred;
    if (current != null) return current;
    for (final o in offerings.all.values) {
      if (o.availablePackages.isNotEmpty) {
        print('[RevenueCat] Using offering "${o.identifier}"');
        return o;
      }
    }
    return null;
  }

  static Package? _pickPackage(
    List<Package> packages, {
    required bool annual,
  }) {
    Package? typed;
    Package? byId;
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      if (annual) {
        if (p.packageType == PackageType.annual) typed = p;
        if (id.contains('annual') ||
            id.contains('year') ||
            id.contains('yearly')) {
          byId = p;
        }
      } else {
        if (p.packageType == PackageType.monthly) typed = p;
        if (id.contains('month') || id.contains('monthly')) byId = p;
      }
    }
    return typed ?? byId;
  }

  PaywallPlans _plansFromPackages({
    Package? monthly,
    Package? annual,
  }) {
    final packages = [monthly, annual].whereType<Package>().toList();
    if (monthly == null && packages.isNotEmpty) monthly = packages.first;
    if (annual == null && packages.length > 1) {
      annual = packages[1];
    } else if (annual == null && packages.length == 1) {
      annual = packages.first;
    }

    var annualMonthly = '\$2.50';
    var annualYearly = '\$29.99';
    if (annual != null) {
      annualYearly = annual.storeProduct.priceString;
      annualMonthly = '\$${(annual.storeProduct.price / 12).toStringAsFixed(2)}';
    }

    return PaywallPlans(
      monthlyPackage: monthly,
      annualPackage: annual,
      monthlyPrice: monthly?.storeProduct.priceString ?? '\$4.99',
      annualMonthlyPrice: annualMonthly,
      annualYearlyPrice: annualYearly,
    );
  }

  Future<PaywallPlans> _plansFromEnvProductIds() async {
    final monthlyId = dotenv.env['REVENUECAT_MONTHLY_PRODUCT_ID']?.trim() ?? '';
    final annualId = dotenv.env['REVENUECAT_ANNUAL_PRODUCT_ID']?.trim() ?? '';
    final ids = <String>[
      if (monthlyId.isNotEmpty) monthlyId,
      if (annualId.isNotEmpty) annualId,
    ];
    if (ids.isEmpty) return const PaywallPlans();

    final products = await Purchases.getProducts(ids);
    print('[RevenueCat] getProducts returned ${products.length} product(s)');
    StoreProduct? monthlyProduct;
    StoreProduct? annualProduct;
    for (final p in products) {
      print('[RevenueCat] Product id=${p.identifier} price=${p.priceString}');
      if (p.identifier == monthlyId) monthlyProduct = p;
      if (p.identifier == annualId) annualProduct = p;
    }

    var annualMonthly = '\$2.50';
    var annualYearly = '\$29.99';
    if (annualProduct != null) {
      annualYearly = annualProduct.priceString;
      annualMonthly =
          '\$${(annualProduct.price / 12).toStringAsFixed(2)}';
    }

    return PaywallPlans(
      monthlyProduct: monthlyProduct,
      annualProduct: annualProduct,
      monthlyPrice: monthlyProduct?.priceString ?? '\$4.99',
      annualMonthlyPrice: annualMonthly,
      annualYearlyPrice: annualYearly,
    );
  }

  /// Presents the native App Store / Play purchase sheet for [package].
  Future<SubscriptionPurchaseOutcome> purchasePackage(Package package) async {
    if (!await ensurePurchasesReady()) {
      return const SubscriptionPurchaseOutcome.failure(
        'Subscriptions are not set up. Add REVENUECAT_API_KEY to .env and '
        'restart the app.',
      );
    }

    final productId = package.storeProduct.identifier;
    print(
      '[RevenueCat] Presenting store purchase sheet — '
      'package=${package.identifier} product=$productId',
    );

    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      final active = _hasPremiumEntitlement(result.customerInfo);
      print('[RevenueCat] Purchase complete — premium active: $active');
      if (active) return const SubscriptionPurchaseOutcome.success();
      return const SubscriptionPurchaseOutcome.failure(
        'Purchase finished but subscription was not activated. '
        'Check RevenueCat entitlement mapping.',
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      print(
        '[RevenueCat] Purchase PlatformException: $code '
        'message=${e.message} details=${e.details}',
      );
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const SubscriptionPurchaseOutcome.cancelled();
      }
      if (code == PurchasesErrorCode.configurationError) {
        return const SubscriptionPurchaseOutcome.failure(
          'RevenueCat is not configured. Restart the app after adding your API key.',
        );
      }
      if (code == PurchasesErrorCode.productNotAvailableForPurchaseError) {
        return SubscriptionPurchaseOutcome.failure(
          'This plan is not available in the App Store yet. '
          'Use a Sandbox Apple ID on a real device, or finish App Store Connect setup. '
          '(${e.message ?? productId})',
        );
      }
      return SubscriptionPurchaseOutcome.failure(
        e.message ?? 'Purchase failed ($code)',
      );
    } catch (e) {
      print('[RevenueCat] Purchase unexpected error: $e');
      return SubscriptionPurchaseOutcome.failure('Purchase failed: $e');
    }
  }

  /// Purchase by [StoreProduct] when offerings did not return packages.
  Future<SubscriptionPurchaseOutcome> purchaseStoreProduct(
    StoreProduct product,
  ) async {
    if (!await ensurePurchasesReady()) {
      return const SubscriptionPurchaseOutcome.failure(
        'Subscriptions are not set up. Add REVENUECAT_API_KEY to .env and '
        'restart the app.',
      );
    }
    print('[RevenueCat] Presenting store sheet for product ${product.identifier}');
    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      final active = _hasPremiumEntitlement(result.customerInfo);
      if (active) return const SubscriptionPurchaseOutcome.success();
      return const SubscriptionPurchaseOutcome.failure(
        'Purchase finished but subscription was not activated.',
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const SubscriptionPurchaseOutcome.cancelled();
      }
      return SubscriptionPurchaseOutcome.failure(
        e.message ?? 'Purchase failed ($code)',
      );
    } catch (e) {
      return SubscriptionPurchaseOutcome.failure('Purchase failed: $e');
    }
  }

  /// Restore purchases — call from paywall restore button.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final active = _hasPremiumEntitlement(info);
      print('[RevenueCat] Restore complete — premium active: $active');
      return active;
    } catch (e) {
      print('[RevenueCat] Restore error: $e');
      return false;
    }
  }

  /// Total saved entries for the current user.
  Future<int> getLifetimeSessionCount() async {
    if (!SupabaseService.isInitialized) {
      print('[Subscription] getLifetimeSessionCount: Supabase not initialized');
      return freeSessionLimit;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[Subscription] getLifetimeSessionCount: no auth user');
      return 0;
    }
    try {
      final rows = await Supabase.instance.client
          .from('entries')
          .select('id')
          .eq('user_id', user.id);
      final count = (rows as List).length;
      print(
        '[Subscription] lifetime session count: $count (user_id=${user.id})',
      );
      return count;
    } catch (e) {
      print('[Subscription] getLifetimeSessionCount error: $e — failing closed');
      return freeSessionLimit;
    }
  }

  /// Returns true if user can start a new session.
  Future<bool> canStartSession() async {
    if (!SupabaseService.isInitialized) {
      print('[Subscription] BLOCKED — Supabase not initialized');
      return false;
    }
    final user = Supabase.instance.client.auth.currentUser;
    print('[Subscription] Gate check for user_id=${user?.id ?? "none"}');
    if (user != null && _hasDevBypass(user.id)) {
      print('[Subscription] ALLOWED — dev bypass for ${user.id}');
      return true;
    }
    final subscribed = await isSubscribed();
    if (subscribed) {
      print('[Subscription] ALLOWED — RevenueCat entitlement active');
      return true;
    }
    final count = await getLifetimeSessionCount();
    final allowed = count < freeSessionLimit;
    if (allowed) {
      final remaining = freeSessionLimit - count;
      print(
        '[Subscription] ALLOWED — free tier ($remaining of $freeSessionLimit '
        'sessions left, $count saved)',
      );
    } else {
      print(
        '[Subscription] BLOCKED — free limit reached ($count >= $freeSessionLimit)',
      );
    }
    return allowed;
  }

  /// Sessions remaining for free users. Returns null if subscribed.
  Future<int?> sessionsRemaining() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _hasDevBypass(user.id)) return null;
    final subscribed = await isSubscribed();
    if (subscribed) return null;
    final count = await getLifetimeSessionCount();
    return (freeSessionLimit - count).clamp(0, freeSessionLimit);
  }
}
