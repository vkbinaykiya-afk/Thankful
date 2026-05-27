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
    final hasTarget = active.containsKey(_entitlementId);
    if (!hasTarget && active.isNotEmpty) {
      print(
        '[RevenueCat] Active entitlements ${active.keys.toList()} but not '
        '"$_entitlementId" — not treating as subscribed',
      );
    }
    return hasTarget;
  }

  /// Links RevenueCat [Purchases.appUserID] to the signed-in Supabase user.
  /// Call before purchase/restore so the dashboard shows your UUID, not $RCAnonymousID.
  static Future<void> ensureRevenueCatUserLinked() async {
    if (!_configured || !SupabaseService.isInitialized) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      print('[RevenueCat] ensureLinked skipped — no Supabase user');
      return;
    }
    try {
      final currentId = await Purchases.appUserID;
      if (currentId == userId) {
        print('[RevenueCat] ensureLinked OK — appUserID=$userId');
        return;
      }
      print(
        '[RevenueCat] ensureLinked — appUserID was "$currentId", logging in as $userId',
      );
      final result = await Purchases.logIn(userId);
      final afterId = await Purchases.appUserID;
      print(
        '[RevenueCat] logIn done — created=${result.created} '
        'appUserID=$afterId originalAppUserId=${result.customerInfo.originalAppUserId}',
      );
    } catch (e) {
      print('[RevenueCat] ensureLinked error: $e');
    }
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

      if (SupabaseService.isInitialized) {
        await ensureRevenueCatUserLinked();
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
      await ensureRevenueCatUserLinked();
      final info = await Purchases.getCustomerInfo();
      final appUserId = await Purchases.appUserID;
      final activeKeys = info.entitlements.active.keys.toList();
      final active = _hasPremiumEntitlement(info);
      print(
        '[RevenueCat] isSubscribed: $active | appUserID=$appUserId | '
        'active entitlements: $activeKeys | looking for: $_entitlementId',
      );
      return active;
    } catch (e) {
      print('[RevenueCat] isSubscribed error: $e — defaulting to false');
      return false;
    }
  }

  /// Navigate to convo or paywall depending on [canStartSession].
  /// Gate for starting a **new** journal session only (not home viewing/sharing).
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
    await ensureRevenueCatUserLinked();

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
      final appUserId = await Purchases.appUserID;
      print(
        '[RevenueCat] Purchase complete — premium active: $active appUserID=$appUserId',
      );
      if (active) return const SubscriptionPurchaseOutcome.success();
      return const SubscriptionPurchaseOutcome.failure(
        'Purchase finished but subscription was not activated. '
        'Check RevenueCat entitlement mapping.',
      );
    } on PlatformException catch (e) {
      return _mapPurchasePlatformException(e, productId: productId);
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
    await ensureRevenueCatUserLinked();
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
      return _mapPurchasePlatformException(
        e,
        productId: product.identifier,
      );
    } catch (e) {
      return SubscriptionPurchaseOutcome.failure('Purchase failed: $e');
    }
  }

  /// Maps StoreKit / RevenueCat errors; treats existing subscription as success.
  Future<SubscriptionPurchaseOutcome> _mapPurchasePlatformException(
    PlatformException e, {
    String? productId,
  }) async {
    final code = PurchasesErrorHelper.getErrorCode(e);
    print(
      '[RevenueCat] Purchase PlatformException: $code '
      'message=${e.message} details=${e.details}',
    );
    if (code == PurchasesErrorCode.purchaseCancelledError) {
      return const SubscriptionPurchaseOutcome.cancelled();
    }
    if (code == PurchasesErrorCode.productAlreadyPurchasedError ||
        code == PurchasesErrorCode.receiptAlreadyInUseError) {
      final synced = await _syncExistingSubscription();
      if (synced) return const SubscriptionPurchaseOutcome.success();
      return const SubscriptionPurchaseOutcome.failure(
        'You already have an active subscription. Try Restore purchase, or restart the app.',
      );
    }
    if (code == PurchasesErrorCode.configurationError) {
      return const SubscriptionPurchaseOutcome.failure(
        'RevenueCat is not configured. Restart the app after adding your API key.',
      );
    }
    if (code == PurchasesErrorCode.productNotAvailableForPurchaseError) {
      return SubscriptionPurchaseOutcome.failure(
        'This plan is not available in the App Store yet. '
        '(${e.message ?? productId ?? 'unknown product'})',
      );
    }
    return SubscriptionPurchaseOutcome.failure(
      e.message ?? 'Purchase failed ($code)',
    );
  }

  /// After "already subscribed" from Apple, refresh RC and check entitlement.
  Future<bool> _syncExistingSubscription() async {
    try {
      print('[RevenueCat] Syncing existing subscription…');
      var info = await Purchases.getCustomerInfo();
      if (_hasPremiumEntitlement(info)) return true;
      info = await Purchases.restorePurchases();
      return _hasPremiumEntitlement(info);
    } catch (e) {
      print('[RevenueCat] _syncExistingSubscription error: $e');
      return false;
    }
  }

  /// Restore purchases — call from paywall restore button.
  Future<bool> restorePurchases() async {
    try {
      await ensureRevenueCatUserLinked();
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

  /// True if user may **create** a new journal session.
  ///
  /// Blocked when: lifetime saved entries >= [freeSessionLimit] (5 in production)
  /// and user has no active subscription. Does not affect viewing or sharing entries.
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

  /// RevenueCat entitlement identifier used by the session gate.
  static String get premiumEntitlementId => _entitlementId;

  /// Snapshot for the Account screen debug panel (TestFlight / QA).
  static Future<SubscriptionDebugSnapshot> loadDebugSnapshot() async {
    final fetchedAt = DateTime.now();
    String? supabaseUserId;
    String? supabaseEmail;
    var devBypass = false;

    if (SupabaseService.isInitialized) {
      final user = Supabase.instance.client.auth.currentUser;
      supabaseUserId = user?.id;
      supabaseEmail = user?.email;
      if (user != null) devBypass = _hasDevBypass(user.id);
    }

    var rcConfigured = _configured;
    String? rcAppUserId;
    String? rcOriginalAppUserId;
    final activeEntitlements = <String>[];
    final allEntitlementKeys = <String>[];
    String? rcError;

    if (rcConfigured) {
      try {
        await ensureRevenueCatUserLinked();
        rcAppUserId = await Purchases.appUserID;
        final info = await Purchases.getCustomerInfo();
        rcOriginalAppUserId = info.originalAppUserId;
        activeEntitlements.addAll(info.entitlements.active.keys);
        allEntitlementKeys.addAll(info.entitlements.all.keys);
      } catch (e) {
        rcError = '$e';
      }
    } else {
      try {
        rcConfigured = await Purchases.isConfigured;
      } catch (_) {
        rcConfigured = false;
      }
    }

    final service = const SubscriptionService();
    var subscribed = false;
    var canStart = false;
    var entryCount = 0;
    int? remaining;
    String? gateError;

    try {
      subscribed = await service.isSubscribed();
      canStart = await service.canStartSession();
      entryCount = await service.getLifetimeSessionCount();
      remaining = await service.sessionsRemaining();
    } catch (e) {
      gateError = '$e';
    }

    return SubscriptionDebugSnapshot(
      fetchedAt: fetchedAt,
      supabaseUserId: supabaseUserId,
      supabaseEmail: supabaseEmail,
      revenueCatConfigured: rcConfigured,
      revenueCatAppUserId: rcAppUserId,
      revenueCatOriginalAppUserId: rcOriginalAppUserId,
      isSubscribed: subscribed,
      canStartSession: canStart,
      lifetimeEntryCount: entryCount,
      freeSessionLimit: freeSessionLimit,
      sessionsRemaining: remaining,
      activeEntitlements: activeEntitlements,
      allEntitlementKeys: allEntitlementKeys,
      expectedEntitlementId: _entitlementId,
      devBypassActive: devBypass,
      ignoreRevenueCatEntitlement:
          FeatureFlags.subscriptionIgnoreRevenueCatEntitlement,
      revenueCatError: rcError,
      gateError: gateError,
    );
  }
}

/// Debug panel payload for Account → Subscription debug.
class SubscriptionDebugSnapshot {
  const SubscriptionDebugSnapshot({
    required this.fetchedAt,
    this.supabaseUserId,
    this.supabaseEmail,
    required this.revenueCatConfigured,
    this.revenueCatAppUserId,
    this.revenueCatOriginalAppUserId,
    required this.isSubscribed,
    required this.canStartSession,
    required this.lifetimeEntryCount,
    required this.freeSessionLimit,
    this.sessionsRemaining,
    required this.activeEntitlements,
    required this.allEntitlementKeys,
    required this.expectedEntitlementId,
    required this.devBypassActive,
    required this.ignoreRevenueCatEntitlement,
    this.revenueCatError,
    this.gateError,
  });

  final DateTime fetchedAt;
  final String? supabaseUserId;
  final String? supabaseEmail;
  final bool revenueCatConfigured;
  final String? revenueCatAppUserId;
  final String? revenueCatOriginalAppUserId;
  final bool isSubscribed;
  final bool canStartSession;
  final int lifetimeEntryCount;
  final int freeSessionLimit;
  final int? sessionsRemaining;
  final List<String> activeEntitlements;
  final List<String> allEntitlementKeys;
  final String expectedEntitlementId;
  final bool devBypassActive;
  final bool ignoreRevenueCatEntitlement;
  final String? revenueCatError;
  final String? gateError;

  bool get appUserIdMatchesSupabase =>
      supabaseUserId != null &&
      revenueCatAppUserId != null &&
      supabaseUserId == revenueCatAppUserId;

  String get displayText {
    final b = StringBuffer();
    void line(String label, Object? value) {
      b.writeln('$label: ${value ?? '—'}');
    }

    line('Fetched', fetchedAt.toIso8601String());
    b.writeln();
    line('Supabase user ID', supabaseUserId);
    line('Email', supabaseEmail);
    b.writeln();
    line('RC configured', revenueCatConfigured);
    line('RC app user ID', revenueCatAppUserId);
    line('RC original app user ID', revenueCatOriginalAppUserId);
    line('RC ID matches Supabase', appUserIdMatchesSupabase);
    if (revenueCatError != null) line('RC error', revenueCatError);
    b.writeln();
    line('Subscribed (gate)', isSubscribed);
    line('Can start session', canStartSession);
    line('Saved entries', lifetimeEntryCount);
    line('Free limit', freeSessionLimit);
    line(
      'Sessions remaining',
      sessionsRemaining?.toString() ?? 'unlimited (subscribed/bypass)',
    );
    line('Dev bypass', devBypassActive);
    line('Ignore RC entitlement flag', ignoreRevenueCatEntitlement);
    if (gateError != null) line('Gate error', gateError);
    b.writeln();
    line('Expected entitlement', expectedEntitlementId);
    line(
      'Active entitlements',
      activeEntitlements.isEmpty ? '(none)' : activeEntitlements.join(', '),
    );
    line(
      'All entitlement keys',
      allEntitlementKeys.isEmpty ? '(none)' : allEntitlementKeys.join(', '),
    );
    return b.toString().trimRight();
  }
}
