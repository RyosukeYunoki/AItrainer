// OnboardingViewModel.swift
// FitEvo

import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {

    var currentStep: Int = 0
    var userName: String = ""
    var selectedGoal: FitnessGoal = .maintenance
    var selectedLevel: FitnessLevel = .beginner
    var currentWeight: Double = 65.0  // kg
    var height: Double = 170.0        // cm
    var weeklyWorkoutDays: Int = 3
    var selectedEquipment: Set<Equipment> = [.bodyweight]
    var healthKitRequested: Bool = false

    var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return true
        case 3: return true
        case 4: return currentWeight > 0 && height > 0
        case 5: return weeklyWorkoutDays >= 1
        case 6: return !selectedEquipment.isEmpty
        default: return false
        }
    }

    func goNext() {
        guard currentStep < 6 else { return }
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func requestHealthKit() async {
        healthKitRequested = true
        // HealthKitManager は AppEnvironment からアクセスするため
        // ここでは単純にフラグを立てるのみ
    }

    func completeOnboarding(modelContext: ModelContext) {
        let profile = UserProfile(
            name: userName.trimmingCharacters(in: .whitespaces),
            fitnessGoal: selectedGoal,
            fitnessLevel: selectedLevel,
            weeklyWorkoutDays: weeklyWorkoutDays,
            availableEquipment: Array(selectedEquipment)
        )
        profile.currentWeight = currentWeight
        profile.height = height
        modelContext.insert(profile)
        try? modelContext.save()

        UserDefaults.standard.set(true, forKey: "fitevo_onboarding_completed")
    }
}
