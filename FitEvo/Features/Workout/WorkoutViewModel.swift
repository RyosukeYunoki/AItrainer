// WorkoutViewModel.swift
// FitEvo

import Foundation
import Observation
import SwiftData

@Observable
final class WorkoutViewModel {

    // MARK: State
    var exercises: [WorkoutExercise] = []
    var currentExerciseIndex: Int = 0
    var currentSet: Int = 1
    var isResting: Bool = false
    var restTimeRemaining: Int = 0
    var isCompleted: Bool = false
    var workoutAction: WorkoutAction?
    var elapsedSeconds: Int = 0

    // MARK: Timer
    private var restTimer: Timer?
    private var workoutTimer: Timer?

    // MARK: Reward
    var earnedReward: Double = 0.0
    var rewardBreakdown: RewardBreakdown?

    // MARK: Dependencies
    private var agentManager: AgentManager
    private var rewardCalculator = RewardCalculator()

    init(agentManager: AgentManager) {
        self.agentManager = agentManager
    }

    // MARK: - Setup

    func setupWorkout(action: WorkoutAction, profile: UserProfile?) {
        workoutAction = action
        let equipment = profile?.equipment ?? [.bodyweight]
        exercises = ExerciseDatabaseLoader.selectExercises(for: action, availableEquipment: equipment)

        // フォールバック: エクササイズが空の場合はデフォルトを使用
        if exercises.isEmpty {
            exercises = createDefaultExercises(for: action)
        }

        startWorkoutTimer()
    }

    // MARK: - Navigation

    var currentExercise: WorkoutExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        let completedSets = exercises.reduce(0) { $0 + $1.completedSets }
        let totalSets = exercises.reduce(0) { $0 + $1.sets }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }

    func completeSet() {
        guard currentExerciseIndex < exercises.count else { return }
        exercises[currentExerciseIndex].completedSets += 1

        let currentEx = exercises[currentExerciseIndex]

        if currentEx.completedSets >= currentEx.sets {
            // 種目完了
            exercises[currentExerciseIndex].isCompleted = true
            if currentExerciseIndex < exercises.count - 1 {
                startRestTimer(seconds: currentEx.restSeconds)
            } else {
                finishWorkout()
            }
        } else {
            // 次のセット前の休憩
            startRestTimer(seconds: currentEx.restSeconds)
        }
    }

    func skipExercise() {
        guard currentExerciseIndex < exercises.count else { return }
        exercises[currentExerciseIndex].isCompleted = true
        moveToNextExercise()
    }

    // MARK: - Rest Timer

    private func startRestTimer(seconds: Int) {
        isResting = true
        restTimeRemaining = seconds
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
            } else {
                self.endRest()
            }
        }
    }

    func skipRest() {
        restTimer?.invalidate()
        endRest()
    }

    private func endRest() {
        restTimer?.invalidate()
        isResting = false
        restTimeRemaining = 0
        moveToNextExercise()
    }

    private func moveToNextExercise() {
        if exercises[currentExerciseIndex].isCompleted {
            if currentExerciseIndex < exercises.count - 1 {
                currentExerciseIndex += 1
                currentSet = 1
            } else {
                finishWorkout()
            }
        } else {
            currentSet = exercises[currentExerciseIndex].completedSets + 1
        }
    }

    // MARK: - Workout Timer

    private func startWorkoutTimer() {
        elapsedSeconds = 0
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    var elapsedTimeFormatted: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Finish

    private func finishWorkout() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        isCompleted = true
    }

    func calculateAndLearnReward(state: FitEvoState, nextState: FitEvoState, modelContext: ModelContext) {
        guard let action = workoutAction else { return }

        let breakdown = rewardCalculator.calculateDetailedReward(
            state: state,
            action: action,
            workoutCompleted: progress >= 0.8
        )
        rewardBreakdown = breakdown
        earnedReward = breakdown.total

        // エージェントに学習させる
        agentManager.currentAgent.learn(
            state: state,
            action: action,
            reward: breakdown.total,
            nextState: nextState
        )

        // SwiftDataにセッションを保存
        let session = WorkoutSession(
            durationMinutes: elapsedSeconds / 60,
            intensity: action.intensity,
            focusAreas: action.focusAreas,
            exercisesCompleted: exercises.filter { $0.isCompleted }.count,
            totalExercises: exercises.count,
            caloriesBurned: (Double(elapsedSeconds) / 60.0) * 6.0,
            reward: breakdown.total,
            algorithmUsed: agentManager.algorithmType,
            subjectiveFatigueAfter: state.subjectiveFatigue
        )
        modelContext.insert(session)
        try? modelContext.save()

        // 継続記録の更新
        let consecutive = UserDefaults.standard.integer(forKey: "fitevo_consecutive_days")
        UserDefaults.standard.set(consecutive + 1, forKey: "fitevo_consecutive_days")
        UserDefaults.standard.set(0, forKey: "fitevo_days_since_workout")
    }

    // MARK: - Default Exercises Fallback

    private func createDefaultExercises(for action: WorkoutAction) -> [WorkoutExercise] {
        let defaults: [(String, String)] = [
            ("pushup_standard", "プッシュアップ"),
            ("squat_bodyweight", "スクワット"),
            ("plank_standard", "プランク"),
            ("lunge_bodyweight", "ランジ"),
            ("burpee", "バーピー")
        ]
        return defaults.prefix(action.exerciseCount).map { (id, name) in
            let exercise = Exercise(
                id: id, name: name, nameEn: name, muscleGroups: ["full_body"],
                equipment: "bodyweight", difficulty: 2, defaultSets: 3, defaultReps: 10,
                caloriesPerMinute: 6.0, description: "\(name)を正しいフォームで行います"
            )
            return WorkoutExercise.from(exercise, intensity: action.intensity)
        }
    }
}
