import 'package:flutter/foundation.dart';

class AdConfig {
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String iosTestAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidReleaseRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: '',
  );
  static const String _androidReleaseInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_ID', defaultValue: '');
  static const String _iosReleaseRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: '',
  );
  static const String _iosReleaseInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static const int interstitialSkipFirstGameOvers = 3;
  static const int interstitialGameOverFrequency = 3;
  static const Duration interstitialCooldown = Duration(seconds: 120);

  static bool get useTestAds {
    return !kReleaseMode ||
        const bool.fromEnvironment('ADMOB_USE_TEST_ADS', defaultValue: true);
  }

  static bool get isSupportedPlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (useTestAds || _iosReleaseRewardedAdUnitId.isEmpty) {
        return iosTestRewardedAdUnitId;
      }
      return _iosReleaseRewardedAdUnitId;
    }

    if (useTestAds || _androidReleaseRewardedAdUnitId.isEmpty) {
      return androidTestRewardedAdUnitId;
    }
    return _androidReleaseRewardedAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (useTestAds || _iosReleaseInterstitialAdUnitId.isEmpty) {
        return iosTestInterstitialAdUnitId;
      }
      return _iosReleaseInterstitialAdUnitId;
    }

    if (useTestAds || _androidReleaseInterstitialAdUnitId.isEmpty) {
      return androidTestInterstitialAdUnitId;
    }
    return _androidReleaseInterstitialAdUnitId;
  }
}
