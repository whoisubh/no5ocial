import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no5ocial/domain/enums/workspace_mode.dart';
import 'package:no5ocial/domain/models/monetization/monetization_models.dart';
import 'package:no5ocial/core/services/monetization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudienceSegmentation Logic', () {
    test('isMultiPersonCompany returns true for team workspace mode', () {
      final result = AudienceSegmentation.isMultiPersonCompany(
        workspaceMode: WorkspaceMode.team,
        memberCount: 1,
        planTier: AccountPlanTier.soloFree,
      );
      expect(result, isTrue);
    });

    test('isMultiPersonCompany returns true when memberCount > 1 even if mode is solo', () {
      final result = AudienceSegmentation.isMultiPersonCompany(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 3,
        planTier: AccountPlanTier.soloFree,
      );
      expect(result, isTrue);
    });

    test('isMultiPersonCompany returns true for B2B plan tiers', () {
      final resultTeam = AudienceSegmentation.isMultiPersonCompany(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
        planTier: AccountPlanTier.b2bTeam,
      );
      expect(resultTeam, isTrue);

      final resultEnt = AudienceSegmentation.isMultiPersonCompany(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
        planTier: AccountPlanTier.b2bEnterprise,
      );
      expect(resultEnt, isTrue);
    });

    test('isMultiPersonCompany returns false for single creator in solo mode on solo plan', () {
      final result = AudienceSegmentation.isMultiPersonCompany(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
        planTier: AccountPlanTier.soloFree,
      );
      expect(result, isFalse);
    });

    test('shouldDisplayAds STRICTLY returns false for multi-person companies', () {
      // Team mode
      expect(
        AudienceSegmentation.shouldDisplayAds(
          workspaceMode: WorkspaceMode.team,
          memberCount: 1,
          planTier: AccountPlanTier.soloFree,
        ),
        isFalse,
      );

      // Multiple members
      expect(
        AudienceSegmentation.shouldDisplayAds(
          workspaceMode: WorkspaceMode.solo,
          memberCount: 4,
          planTier: AccountPlanTier.soloFree,
        ),
        isFalse,
      );

      // B2B Plan
      expect(
        AudienceSegmentation.shouldDisplayAds(
          workspaceMode: WorkspaceMode.solo,
          memberCount: 1,
          planTier: AccountPlanTier.b2bTeam,
        ),
        isFalse,
      );
    });

    test('shouldDisplayAds STRICTLY returns false for paid subscribers (Solo Pro)', () {
      expect(
        AudienceSegmentation.shouldDisplayAds(
          workspaceMode: WorkspaceMode.solo,
          memberCount: 1,
          planTier: AccountPlanTier.soloPro,
        ),
        isFalse,
      );
    });

    test('shouldDisplayAds returns true ONLY for solo creator on soloFree tier', () {
      expect(
        AudienceSegmentation.shouldDisplayAds(
          workspaceMode: WorkspaceMode.solo,
          memberCount: 1,
          planTier: AccountPlanTier.soloFree,
        ),
        isTrue,
      );
    });
  });

  group('DayPassStatus & DailyRewardCeiling', () {
    test('DayPassStatus correctly reflects active vs expired duration', () {
      final now = DateTime.now().toUtc();
      final activePass = DayPassStatus(
        activatedAt: now,
        expiresAt: now.add(const Duration(hours: 12)),
        videosWatchedInSequence: 0,
      );

      expect(activePass.isActive, isTrue);
      expect(activePass.remainingTime.inHours, greaterThanOrEqualTo(11));

      final expiredPass = DayPassStatus(
        activatedAt: now.subtract(const Duration(hours: 30)),
        expiresAt: now.subtract(const Duration(hours: 6)),
        videosWatchedInSequence: 0,
      );

      expect(expiredPass.isActive, isFalse);
      expect(expiredPass.remainingTime, equals(Duration.zero));
    });

    test('DayPassStatus tracks capped sequence threshold of 3 videos', () {
      const emptyPass = DayPassStatus(videosWatchedInSequence: 0);
      expect(emptyPass.isSequenceComplete, isFalse);
      expect(emptyPass.sequenceProgress, 0.0);

      const partialPass = DayPassStatus(videosWatchedInSequence: 2);
      expect(partialPass.isSequenceComplete, isFalse);
      expect(partialPass.sequenceProgress, closeTo(0.66, 0.01));

      const completePass = DayPassStatus(videosWatchedInSequence: 3);
      expect(completePass.isSequenceComplete, isTrue);
      expect(completePass.sequenceProgress, 1.0);
    });

    test('DailyRewardCeiling enforces hardcoded anti-bot and API limits', () {
      final ceiling = DailyRewardCeiling.today().copyWith(
        dayPassesUnlockedToday: 1,
        scheduledPostsToday: 10,
        offerwallCreditsEarnedToday: 50,
      );

      expect(ceiling.hasReachedDayPassLimit, isTrue);
      expect(ceiling.hasReachedScheduledPostCeiling, isTrue);
      expect(ceiling.hasReachedOfferwallLimit, isTrue);
    });
  });

  group('MonetizationService Bottleneck Evaluations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('evaluateSchedulingAccess blocks multi-person companies without B2B plan', () async {
      final service = MonetizationService.instance;
      await service.init();
      await service.upgradePlan(AccountPlanTier.soloFree);

      final result = service.evaluateSchedulingAccess(
        workspaceMode: WorkspaceMode.team,
        memberCount: 2,
      );

      expect(result.canSchedule, isFalse);
      expect(result.bottleneck, equals(SystemBottleneckType.teamSeatExpansion));
    });

    test('evaluateSchedulingAccess blocks Solo Free when Day Pass is inactive', () async {
      final service = MonetizationService.instance;
      await service.init();
      await service.upgradePlan(AccountPlanTier.soloFree);

      final result = service.evaluateSchedulingAccess(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
      );

      expect(result.canSchedule, isFalse);
      expect(result.bottleneck, equals(SystemBottleneckType.dayPassExpired));
    });

    test('evaluateSchedulingAccess allows paid Solo Pro without Day Pass friction', () async {
      final service = MonetizationService.instance;
      await service.init();
      await service.upgradePlan(AccountPlanTier.soloPro);

      final result = service.evaluateSchedulingAccess(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
      );

      expect(result.canSchedule, isTrue);
      expect(result.bottleneck, isNull);
    });

    test('advanceDayPassVideoSequence unlocks 24-hour pass after 3 rewarded views', () async {
      final service = MonetizationService.instance;
      await service.init();
      await service.upgradePlan(AccountPlanTier.soloFree);

      // Step 1
      final res1 = await service.advanceDayPassVideoSequence();
      expect(res1.success, isTrue);
      expect(res1.passUnlocked, isFalse);
      expect(service.dayPassStatus.videosWatchedInSequence, 1);

      // Step 2
      final res2 = await service.advanceDayPassVideoSequence();
      expect(res2.success, isTrue);
      expect(res2.passUnlocked, isFalse);
      expect(service.dayPassStatus.videosWatchedInSequence, 2);

      // Step 3 -> Unlocks 24-hour pass!
      final res3 = await service.advanceDayPassVideoSequence();
      expect(res3.success, isTrue);
      expect(res3.passUnlocked, isTrue);
      expect(service.dayPassStatus.isActive, isTrue);
      expect(service.dayPassStatus.videosWatchedInSequence, 0);

      // Now scheduling access is permitted
      final access = service.evaluateSchedulingAccess(
        workspaceMode: WorkspaceMode.solo,
        memberCount: 1,
      );
      expect(access.canSchedule, isTrue);
      expect(access.bottleneck, isNull);
    });
  });
}
