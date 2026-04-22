// ContentView.swift (RootView)
// FitEvo
//
// アプリのルートビュー。
// オンボーディング完了状態に応じてメイン画面またはオンボーディングを表示する。

import SwiftUI
import SwiftData

// MARK: - RootView

/// オンボーディング状態を管理するルートビュー。
struct RootView: View {
    @Environment(AgentManager.self) private var agentManager
    @Environment(HealthKitManager.self) private var healthKitManager

    @State private var isOnboardingCompleted = UserDefaults.standard.bool(forKey: "fitevo_onboarding_completed")
    @State private var showAIReady = false

    var body: some View {
        if isOnboardingCompleted && !showAIReady {
            MainTabView(agentManager: agentManager, healthKitManager: healthKitManager)
        } else if showAIReady {
            AIReadyView {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAIReady = false
                }
            }
            .transition(.opacity)
        } else {
            OnboardingView(viewModel: OnboardingViewModel()) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isOnboardingCompleted = true
                    showAIReady = true
                }
            }
        }
    }
}

// MARK: - MainTabView

/// メインのタブナビゲーション
struct MainTabView: View {
    @Bindable var agentManager: AgentManager
    var healthKitManager: HealthKitManager

    @State private var selectedTab = 0
    @State private var showWorkout = false
    @State private var workoutAction: WorkoutAction = WorkoutAction.standardWorkout(focusAreas: [.fullBody])
    @State private var currentState: FitEvoState = .mock

    @AppStorage("fitevo_tutorial_shown") private var tutorialShown = false
    @State private var showTutorial = false

    // ViewModels（タブ間でインスタンスを維持）
    @State private var dashboardViewModel: DashboardViewModel
    @State private var workoutViewModel: WorkoutViewModel
    @State private var progressViewModel: ProgressViewModel

    init(agentManager: AgentManager, healthKitManager: HealthKitManager) {
        self.agentManager = agentManager
        self.healthKitManager = healthKitManager
        _dashboardViewModel = State(initialValue: DashboardViewModel(agentManager: agentManager, healthKitManager: healthKitManager))
        _workoutViewModel = State(initialValue: WorkoutViewModel(agentManager: agentManager))
        _progressViewModel = State(initialValue: ProgressViewModel(agentManager: agentManager))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: ダッシュボード
            DashboardView(
                viewModel: dashboardViewModel,
                onStartWorkout: { action in
                    workoutAction = action
                    currentState = dashboardViewModel.currentState
                    showWorkout = true
                }
            )
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(0)

            // Tab 1: 進捗
            ProgressAnalyticsView(viewModel: progressViewModel)
                .tabItem {
                    Label("進捗", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            // Tab 2: 体型記録
            BodyProgressView()
                .tabItem {
                    Label("体型", systemImage: "figure.stand")
                }
                .tag(2)

            // Tab 3: 設定
            SettingsView(agentManager: agentManager)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(AppTheme.Colors.primary)
        .preferredColorScheme(.light)
        .overlay {
            if showTutorial {
                TutorialOverlayView(isShowing: $showTutorial)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if !tutorialShown {
                // ダッシュボードが描画された後に少し遅らせて表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showTutorial = true
                    tutorialShown = true
                }
            }
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutView(
                viewModel: workoutViewModel,
                action: workoutAction,
                currentState: currentState,
                onComplete: {
                    showWorkout = false
                    Task {
                        await dashboardViewModel.loadDashboard(profile: nil)
                    }
                }
            )
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, WorkoutSession.self, WeeklyWorkoutPlan.self], inMemory: true)
}
