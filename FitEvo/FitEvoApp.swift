// FitEvoApp.swift
// FitEvo
//
// アプリのエントリーポイント。
// SwiftDataのModelContainerを設定し、環境オブジェクトを提供する。

import SwiftUI
import SwiftData

@main
struct FitEvoApp: App {

    // MARK: 環境オブジェクト（アプリ全体で共有）

    @State private var agentManager = AgentManager()
    @State private var healthKitManager = HealthKitManager()

    // MARK: SwiftData Container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            WorkoutSession.self,
            WeeklyWorkoutPlan.self,
            BodyRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(agentManager)
                .environment(healthKitManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
