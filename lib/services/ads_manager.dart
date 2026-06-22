import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:toilet_survivor/config/ad_config.dart';

class AdsManager extends ChangeNotifier {
  AdsManager._();

  static final AdsManager instance = AdsManager._();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _initialized = false;
  bool _rewardedLoading = false;
  bool _interstitialLoading = false;
  int _gameOverCount = 0;
  DateTime? _lastInterstitialShownAt;

  bool get isRewardedReviveReady => _rewardedAd != null;

  Future<void> initialize() async {
    if (_initialized || !AdConfig.isSupportedPlatform) {
      return;
    }

    _initialized = true;
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadInterstitialAd();
  }

  void recordGameOver() {
    _gameOverCount++;
  }

  void loadRewardedAd() {
    if (!_initialized ||
        _rewardedLoading ||
        _rewardedAd != null ||
        !AdConfig.isSupportedPlatform) {
      return;
    }

    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob rewarded loaded');
          _rewardedLoading = false;
          _rewardedAd = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob rewarded failed: $error');
          _rewardedLoading = false;
          _rewardedAd = null;
          notifyListeners();
          Future<void>.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  bool showRewardedRevive({required VoidCallback onRewarded}) {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd = null;
    notifyListeners();

    var rewardEarned = false;
    var completed = false;

    void complete() {
      if (completed) {
        return;
      }
      completed = true;
      ad.dispose();
      loadRewardedAd();
      if (rewardEarned) {
        onRewarded();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('AdMob rewarded shown');
      },
      onAdDismissedFullScreenContent: (_) {
        debugPrint('AdMob rewarded closed');
        complete();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('AdMob rewarded failed to show: $error');
        complete();
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        debugPrint('AdMob rewarded earned: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );
    return true;
  }

  void loadInterstitialAd() {
    if (!_initialized ||
        _interstitialLoading ||
        _interstitialAd != null ||
        !AdConfig.isSupportedPlatform) {
      return;
    }

    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob interstitial loaded');
          _interstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob interstitial failed: $error');
          _interstitialLoading = false;
          _interstitialAd = null;
          Future<void>.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAfterGameOver({
    required bool skipBecauseRewardedRevive,
    required VoidCallback onComplete,
  }) {
    final ad = _interstitialAd;
    if (!_shouldShowInterstitial(skipBecauseRewardedRevive) || ad == null) {
      loadInterstitialAd();
      onComplete();
      return;
    }

    _interstitialAd = null;
    _lastInterstitialShownAt = DateTime.now();

    var completed = false;
    void complete() {
      if (completed) {
        return;
      }
      completed = true;
      ad.dispose();
      loadInterstitialAd();
      onComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('AdMob interstitial shown');
      },
      onAdDismissedFullScreenContent: (_) {
        debugPrint('AdMob interstitial closed');
        complete();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('AdMob interstitial failed to show: $error');
        complete();
      },
    );

    ad.show();
  }

  bool _shouldShowInterstitial(bool skipBecauseRewardedRevive) {
    if (skipBecauseRewardedRevive) {
      return false;
    }
    if (_gameOverCount <= AdConfig.interstitialSkipFirstGameOvers) {
      return false;
    }
    if ((_gameOverCount - AdConfig.interstitialSkipFirstGameOvers) %
            AdConfig.interstitialGameOverFrequency !=
        0) {
      return false;
    }

    final lastShownAt = _lastInterstitialShownAt;
    if (lastShownAt == null) {
      return true;
    }

    return DateTime.now().difference(lastShownAt) >=
        AdConfig.interstitialCooldown;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
