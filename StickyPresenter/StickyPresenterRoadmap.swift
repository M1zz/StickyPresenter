//
//  StickyPresenterRoadmap.swift
//  StickyPresenter
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.1.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지).
//       번역은 `Resources/{en,ko}.lproj/Localizable.strings` 의 `roadmap.<id>.title|detail` 키에 둘 다 넣는다.
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension StickyPresenterSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 다음에 만들어요
        .init(id: "a11y.voiceover", status: .planned,
              title: NSLocalizedString("roadmap.a11y.voiceover.title", comment: "Roadmap item: Better VoiceOver support"),
              detail: NSLocalizedString("roadmap.a11y.voiceover.detail", comment: "Roadmap item detail: Better VoiceOver support")),
        .init(id: "a11y.contrast", status: .planned,
              title: NSLocalizedString("roadmap.a11y.contrast.title", comment: "Roadmap item: Easier-to-see colors"),
              detail: NSLocalizedString("roadmap.a11y.contrast.detail", comment: "Roadmap item detail: Easier-to-see colors")),
        .init(id: "a11y.motion", status: .planned,
              title: NSLocalizedString("roadmap.a11y.motion.title", comment: "Roadmap item: Reduced motion"),
              detail: NSLocalizedString("roadmap.a11y.motion.detail", comment: "Roadmap item detail: Reduced motion")),
        .init(id: "lang.more", status: .planned,
              title: NSLocalizedString("roadmap.lang.more.title", comment: "Roadmap item: More languages"),
              detail: NSLocalizedString("roadmap.lang.more.detail", comment: "Roadmap item detail: More languages")),
        .init(id: "whatsnew", status: .planned,
              title: NSLocalizedString("roadmap.whatsnew.title", comment: "Roadmap item: What’s new"),
              detail: NSLocalizedString("roadmap.whatsnew.detail", comment: "Roadmap item detail: What’s new")),
        .init(id: "feedback.reply", status: .planned,
              title: NSLocalizedString("roadmap.feedback.reply.title", comment: "Roadmap item: Replies to your feedback"),
              detail: NSLocalizedString("roadmap.feedback.reply.detail", comment: "Roadmap item detail: Replies to your feedback")),
        .init(id: "sync.icloud", status: .planned,
              title: NSLocalizedString("roadmap.sync.icloud.title", comment: "Roadmap item: Notes on all your Macs"),
              detail: NSLocalizedString("roadmap.sync.icloud.detail", comment: "Roadmap item detail: Notes on all your Macs")),
        .init(id: "backup", status: .planned,
              title: NSLocalizedString("roadmap.backup.title", comment: "Roadmap item: Export and import notes"),
              detail: NSLocalizedString("roadmap.backup.detail", comment: "Roadmap item detail: Export and import notes")),
        .init(id: "notifications", status: .planned,
              title: NSLocalizedString("roadmap.notifications.title", comment: "Roadmap item: Timer alerts"),
              detail: NSLocalizedString("roadmap.notifications.detail", comment: "Roadmap item detail: Timer alerts")),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. 설정 창이 내비게이션 스택이 아니라서 시트로 띄운다.
/// "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 창을 연다.
struct RoadmapScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedback = false

    var body: some View {
        NavigationStack {
            LeeoRoadmapView<StickyPresenterSpec>(onSuggest: { showFeedback = true })
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L("Close")) { dismiss() }
                    }
                }
        }
        .frame(width: 460, height: 520)
        .sheet(isPresented: $showFeedback) {
            NavigationStack {
                LeeoFeedbackView<StickyPresenterSpec>(initialType: .feature)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L("Close")) { showFeedback = false }
                        }
                    }
            }
            .frame(width: 460, height: 560)
        }
    }
}
