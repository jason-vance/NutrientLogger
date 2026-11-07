//
//  OnboardingFunnelAnalyticsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/7/26.
//

import Testing

struct OnboardingFunnelAnalyticsTests {

    private let engine = MockAnalyticsEngine()
    private var analytics: DefaultAnalytics { DefaultAnalytics(analyticsEngine: engine) }

    private func lastEvent() -> (name: String, parameters: [String: Any])? {
        engine.loggedEvents.last.map { ($0.0, $0.1) }
    }

    @Test func logsTimeSpentOnAStep() {
        analytics.onboardingStepCompleted(stepName: "food_breakdown", stepIndex: 2, secondsOnStep: 14)
        let event = lastEvent()
        #expect(event?.name == "onboarding_step_completed")
        #expect(event?.parameters["step_name"] as? String == "food_breakdown")
        #expect(event?.parameters["step_index"] as? Int == 2)
        #expect(event?.parameters["seconds_on_step"] as? Int == 14)
    }

    @Test func logsGoingBack() {
        analytics.onboardingStepBack(stepName: "demo", stepIndex: 3)
        #expect(lastEvent()?.name == "onboarding_step_back")
        #expect(lastEvent()?.parameters["step_name"] as? String == "demo")
    }

    @Test func completionCarriesTheAnswersAndOutcome() {
        analytics.onboardingCompleted(totalSeconds: 95, diet: "carnivore", concern: "energy", subscribed: true)
        let event = lastEvent()
        #expect(event?.name == "onboarding_completed")
        #expect(event?.parameters["total_seconds"] as? Int == 95)
        #expect(event?.parameters["diet"] as? String == "carnivore")
        #expect(event?.parameters["concern"] as? String == "energy")
        #expect(event?.parameters["subscribed"] as? Int == 1)
    }

    @Test func personalizationSetsUserProperties() {
        analytics.onboardingPersonalizationSelected(diet: "ketoLowCarb", concern: "weightLoss")
        #expect(engine.userProperties["diet"] == "ketoLowCarb")
        #expect(engine.userProperties["nutrition_focus"] == "weightLoss")

        analytics.settingsPersonalizationUpdated(diet: "paleo", concern: "generalHealth")
        #expect(engine.userProperties["diet"] == "paleo")
        #expect(engine.userProperties["nutrition_focus"] == "generalHealth")
    }

    @Test func onboardingPaywallHasItsOwnTrigger() {
        analytics.paywallShown(trigger: .onboarding)
        #expect(lastEvent()?.parameters["trigger"] as? String == "onboarding")
    }

    @Test func breakdownStepLogsNoFoodName() {
        analytics.onboardingFoodBreakdownViewed(diet: "carnivore")
        #expect(lastEvent()?.name == "onboarding_food_breakdown_viewed")
        #expect(lastEvent()?.parameters["diet"] as? String == "carnivore")
        #expect(lastEvent()?.parameters["food"] == nil)
    }
}
