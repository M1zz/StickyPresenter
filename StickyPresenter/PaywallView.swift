import SwiftUI
import AppKit
import StoreKit
import LeeoKit

// MARK: - 페이월
//
// 세 칸(무료 · Plus · Pro)을 파는 한 장.
// 머리말 → (막힌 까닭) → 유료 칸 카드(들어온 자리의 칸이 먼저) → 무료 칸 → 비교표 → 약관.
// 칸마다 연 구독과 평생을 먼저 보이고, 주 · 월 구독은 펼쳐서 고른다.
// 스토어에서 불러오지 못한 상품의 단추는 서지 않는다.

/// 무엇 때문에 페이월이 떴는가. 그 칸을 맨 위에 세우고 까닭을 먼저 말한다.
enum PaywallCause: Hashable {
    case feature(PlanFeature)
    /// 발표 타이머를 5번 끝까지 쓴 뒤 한 번.
    case talks

    var tier: PlanTier {
        switch self {
        case .feature(let feature): return feature.tier
        case .talks:                return .plus
        }
    }
}

// MARK: - 창

/// 페이월 · 구독 졸업 창. 메뉴 막대 앱이라 시트를 얹을 앱 창이 없어 창을 직접 띄운다.
@MainActor
enum Paywall {
    private static var window: NSWindow?
    /// 이번 실행에서 이미 한 번 보인 자리 — 테마를 넘길 때마다 페이월이 뜨지 않게.
    private static var offeredThisRun: Set<PaywallCause> = []

    /// 막힌 자리에서 부른다.
    static func present(_ cause: PaywallCause? = nil, initialTerm: PlanTerm = .yearly) {
        show(PaywallView(cause: cause, initialTerm: initialTerm, onClose: close),
             title: "StickyPresenter Plus · Pro")
        LeeoAnalyticsCenter.track(.paywallShown(reason: cause.map(reasonName) ?? "settings"))
    }

    /// 지나가다 마주친 자리(테마 넘기기 · 리모컨)는 실행마다 한 번만 보인다.
    static func offer(_ cause: PaywallCause) {
        guard !offeredThisRun.contains(cause) else { return }
        offeredThisRun.insert(cause)
        present(cause)
    }

    /// 구독 중인 사람의 '평생으로 바꾸기'. 졸업가가 없으면 평생을 고른 페이월을 연다.
    static func presentGraduation() {
        let purchases = Purchases.shared
        guard purchases.subscription != nil, let graduate = purchases.product(PlanEntitlement.graduateID) else {
            present(initialTerm: .lifetime)
            return
        }
        LeeoGraduation.markOffered()
        // '다음에' · '닫기' 는 LeeoKit 화면의 dismiss 다. 시트가 아니라 창이라 제목 막대의 닫기로도 닫힌다.
        show(LeeoGraduationOfferView(graduate: graduate, onPurchased: { await Purchases.shared.afterTransaction() }),
             title: LeeoLadderText.graduateTitle)
    }

    static func close() {
        let closing = window
        window = nil
        closing?.contentView = nil
        DispatchQueue.main.async { closing?.close() }
    }

    private static func show<Content: View>(_ content: Content, title: String) {
        close()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 680),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)
        window.title = title
        // 노트 · 타이머 패널(최상위 레벨) 위에 뜬다 — 막힌 자리 바로 앞에 보여야 한다.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false  // Swift ARC와 충돌 방지 (이중 해제 크래시)
        window.minSize = NSSize(width: 480, height: 420)
        window.contentView = NSHostingView(rootView: content)
        window.center()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private static func reasonName(_ cause: PaywallCause) -> String {
        switch cause {
        case .feature(let feature): return feature.rawValue
        case .talks:                return "talks"
        }
    }
}

// MARK: - 화면

struct PaywallView: View {
    let cause: PaywallCause?
    let onClose: () -> Void

    @ObservedObject private var purchases = Purchases.shared
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 이 페이월 창에 띄운다 (→ Purchases.purchase).
    @Environment(\.purchase) private var purchaseAction

    @State private var plusTerm: PlanTerm
    @State private var proTerm: PlanTerm
    @State private var loadingProducts = true

    init(cause: PaywallCause?, initialTerm: PlanTerm = .yearly, onClose: @escaping () -> Void) {
        self.cause = cause
        self.onClose = onClose
        _plusTerm = State(initialValue: initialTerm)
        _proTerm = State(initialValue: initialTerm)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let cause, let reason = reason(cause) { reasonBox(reason) }
                plansStatus
                ForEach(paidOrder, id: \.self) { tierCard($0) }
                freeCard
                PlanComparisonTable()
                if let message = purchases.failureMessage, !purchases.products.isEmpty {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
                legal
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 480, minHeight: 420)
        .task { await loadPlans() }
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "StickyPresenter Plus · Pro")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(L("plan.subtitle"))
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reason(_ cause: PaywallCause) -> (title: String, note: String)? {
        switch cause {
        case .talks:
            return (L("plan.reason.talks.title", Purchases.talksMoment), L("plan.reason.talks.note"))
        case .feature(let feature):
            switch feature {
            case .notes:       return (L("plan.reason.notes.title", PlanEntitlement.freeNotes), L("plan.reason.notes.note"))
            case .timers:      return (L("plan.reason.timers.title", PlanEntitlement.freeTimers), L("plan.reason.timers.note"))
            case .chameleon:   return (L("plan.reason.chameleon.title"), L("plan.reason.chameleon.note"))
            case .presets:     return (L("plan.reason.presets.title"), L("plan.reason.presets.note"))
            case .music:       return (L("plan.reason.music.title"), L("plan.reason.music.note"))
            case .mirror:      return (L("plan.reason.mirror.title"), L("plan.reason.mirror.note"))
            case .remote:      return (L("plan.reason.remote.title", PlanEntitlement.freeRemoteTalks), L("plan.reason.remote.note"))
            case .timerWindow: return (L("plan.reason.timerWindow.title"), L("plan.reason.timerWindow.note"))
            case .shortcuts:   return (L("plan.reason.shortcuts.title"), L("plan.reason.shortcuts.note"))
            case .widget:      return nil
            }
        }
    }

    private func reasonBox(_ reason: (title: String, note: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reason.title).font(.headline)
            Text(reason.note)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// 유료 칸의 차례. 들어온 자리의 칸이 먼저다.
    private var paidOrder: [PlanTier] { cause?.tier == .pro ? [.pro, .plus] : [.plus, .pro] }

    // MARK: 칸 카드

    private func tierCard(_ tier: PlanTier) -> some View {
        card(highlighted: cause?.tier == tier && purchases.tier < tier) {
            cardTitle(tier, current: purchases.tier == tier)
            if tier == .plus {
                tagline(L("plan.plus.tagline"))
                row("infinity", L("plan.plus.unlimited"))
                row("eyedropper.halffull", L("plan.plus.chameleon"))
                row("slider.horizontal.3", L("plan.plus.presets"))
                row("music.note", L("plan.plus.music"))
                row("arrow.left.arrow.right", L("plan.plus.mirror"))
            } else {
                tagline(L("plan.pro.tagline"))
                row("square.stack.3d.up", L("plan.pro.everythingInPlus"))
                row("iphone", L("plan.pro.remote"))
                row("macwindow.on.rectangle", L("plan.pro.timerWindow"))
                row("waveform", L("plan.pro.shortcuts"))
                row("rectangle.grid.1x2", L("plan.pro.widget"))
            }
            // 이미 이 칸 이상이면 살 것이 없다. 구독을 평생으로 바꾸는 길은 설정에 있다.
            if purchases.tier < tier, hasAnyProduct(tier) {
                PlanTermPicker(term: term(for: tier), products: products(tier))
                    .padding(.top, 4)
                buyButton(tier)
            }
        }
    }

    private var freeCard: some View {
        card(highlighted: false) {
            cardTitle(.free, current: purchases.gatesActive && purchases.tier == .free)
            tagline(L("plan.free.tagline"))
        }
    }

    private func term(for tier: PlanTier) -> Binding<PlanTerm> {
        tier == .plus ? $plusTerm : $proTerm
    }

    private var upgradesToPro: Bool { purchases.ownsLifetime(.plus) }

    /// 칸의 상품들. **Plus 평생을 산 사람의 Pro 평생 자리에는 올리기 상품을 세운다.**
    private func products(_ tier: PlanTier) -> PlanTermPicker.Products {
        typealias E = PlanEntitlement
        if tier == .plus {
            return .init(weekly: purchases.product(E.plusWeeklyID), monthly: purchases.product(E.plusMonthlyID),
                         yearly: purchases.product(E.plusYearlyID), lifetime: purchases.product(E.plusLifetimeID))
        }
        return .init(weekly: purchases.product(E.proWeeklyID), monthly: purchases.product(E.proMonthlyID),
                     yearly: purchases.product(E.proYearlyID),
                     lifetime: purchases.product(upgradesToPro ? E.upgradeID : E.proLifetimeID))
    }

    private func hasAnyProduct(_ tier: PlanTier) -> Bool {
        PlanTerm.allCases.contains { products(tier)[$0] != nil }
    }

    private func buyButton(_ tier: PlanTier) -> some View {
        let chosen = term(for: tier).wrappedValue
        let product = products(tier)[chosen]
        let title: String
        switch chosen {
        case .weekly:  title = L("plan.buy.weekly")
        case .monthly: title = L("plan.buy.monthly")
        case .yearly:  title = L("plan.buy.yearly")
        case .lifetime where tier == .pro && upgradesToPro: title = L("plan.buy.upgrade")
        case .lifetime: title = L("plan.buy.lifetime")
        }
        return Button {
            guard let product else { return }
            Task {
                await purchases.purchase(product, using: purchaseAction)
                if purchases.tier >= tier { onClose() }
            }
        } label: {
            Group {
                if purchases.isWorking {
                    ProgressView().controlSize(.small)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(purchases.isWorking || product == nil)
        .accessibilityLabel(title)
    }

    // MARK: 요금제를 못 불러왔을 때

    @ViewBuilder
    private var plansStatus: some View {
        if purchases.products.isEmpty && loadingProducts {
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text(L("plan.loading")).font(.body).foregroundStyle(.secondary)
            }
        } else if purchases.products.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(L("plan.loadFailed"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label(L("plan.reload"), systemImage: "arrow.clockwise")
                }
            }
        }
    }

    /// 첫 조회가 빈손이면 한 번 더 청한다. 샌드박스(심사 환경)는 첫 조회가 비어 오는 일이 잦다.
    private func loadPlans() async {
        loadingProducts = true
        await purchases.loadProducts()
        if purchases.products.isEmpty {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await purchases.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 12) {
            if purchases.products.contains(where: { $0.subscription != nil }) {
                Text(L("plan.legal.subscription"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 18) {
                if let terms = StickyPresenterSpec.monetization.subscriptionTermsURL {
                    Button(L("plan.terms")) { openURL(terms) }.buttonStyle(.link)
                }
                Button(L("plan.privacy")) { openURL(StickyPresenterSpec.legal.privacyURL) }.buttonStyle(.link)
                Spacer(minLength: 0)
                Button(L("plan.restore")) {
                    Task {
                        await purchases.restore()
                        if purchases.tier >= (cause?.tier ?? .plus) { onClose() }
                    }
                }
                .disabled(purchases.isWorking)
                Button(L("plan.later"), action: onClose)
                    .keyboardShortcut(.cancelAction)
            }
            .font(.body)
        }
    }

    // MARK: 부속

    private func card<Content: View>(highlighted: Bool, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return VStack(alignment: .leading, spacing: 10, content: content)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(Color.primary.opacity(0.05))
                shape.strokeBorder(highlighted ? Color.accentColor : .clear, lineWidth: 2)
            }
    }

    private func cardTitle(_ tier: PlanTier, current: Bool) -> some View {
        HStack(spacing: 8) {
            Text(tier.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            if current {
                Text(L("plan.current"))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }

    private func tagline(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func row(_ icon: String, _ title: String) -> some View {
        Label {
            Text(title).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.accentColor)
        }
        .font(.body)
    }
}

extension PlanTier {
    var title: String {
        switch self {
        case .free: return L("plan.tier.free")
        case .plus: return "StickyPresenter Plus"
        case .pro:  return "StickyPresenter Pro"
        }
    }

    /// 표 머리처럼 좁은 자리.
    var shortTitle: String {
        switch self {
        case .free: return L("plan.tier.free")
        case .plus: return "Plus"
        case .pro:  return "Pro"
        }
    }
}

// MARK: - 주 · 월 · 연 · 평생

enum PlanTerm: CaseIterable {
    case weekly, monthly, yearly, lifetime
}

/// 칸 하나의 길 고르기. 연 구독 · 평생을 먼저 보이고, 주 · 월은 펼쳐서 고른다.
struct PlanTermPicker: View {
    struct Products {
        var weekly, monthly, yearly, lifetime: Product?

        subscript(term: PlanTerm) -> Product? {
            switch term {
            case .weekly:   return weekly
            case .monthly:  return monthly
            case .yearly:   return yearly
            case .lifetime: return lifetime
            }
        }
    }

    @Binding var term: PlanTerm
    let products: Products
    @State private var showsShortTerms = false
    @State private var introEligible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                option(.yearly)
                option(.lifetime)
            }
            if hasShortTerms {
                if showsShortTerms || term == .weekly || term == .monthly {
                    HStack(spacing: 8) {
                        option(.weekly)
                        option(.monthly)
                    }
                } else {
                    Button(L("plan.showShortTerms")) { showsShortTerms = true }
                        .buttonStyle(.link)
                        .font(.body)
                }
            }
            if let note {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            // 고른 길을 못 불러왔으면 고를 수 있는 첫 길로 옮긴다.
            if products[term] == nil,
               let first = [PlanTerm.yearly, .lifetime, .monthly, .weekly].first(where: { products[$0] != nil }) {
                term = first
            }
        }
        .task(id: products.yearly?.id) {
            introEligible = await products.yearly?.subscription?.isEligibleForIntroOffer ?? false
        }
    }

    private var hasShortTerms: Bool { products.weekly != nil || products.monthly != nil }

    private var note: String? {
        switch term {
        case .yearly:
            guard introEligible, let offer = products.yearly?.subscription?.introductoryOffer,
                  offer.paymentMode == .payUpFront || offer.paymentMode == .payAsYouGo else { return nil }
            return String(format: LeeoLadderText.introFormat, offer.displayPrice)
        case .lifetime:
            guard let yearly = products.yearly?.price, let lifetime = products.lifetime?.price, yearly > 0 else { return nil }
            let years = Int(NSDecimalNumber(decimal: lifetime / yearly).doubleValue.rounded(.down))
            return years >= 2 ? String(format: LeeoLadderText.lifetimeWorthFormat, years) : nil
        case .weekly, .monthly:
            return nil
        }
    }

    private func title(_ term: PlanTerm) -> String {
        switch term {
        case .weekly:   return L("plan.term.weekly")
        case .monthly:  return L("plan.term.monthly")
        case .yearly:   return LeeoLadderText.yearly
        case .lifetime: return LeeoLadderText.lifetime
        }
    }

    private func price(_ term: PlanTerm) -> String? {
        guard let price = products[term]?.displayPrice else { return nil }
        switch term {
        case .weekly:   return L("plan.price.perWeek", price)
        case .monthly:  return L("plan.price.perMonth", price)
        case .yearly:   return String(format: LeeoLadderText.perYearFormat, price)
        case .lifetime: return price
        }
    }

    @ViewBuilder
    private func option(_ value: PlanTerm) -> some View {
        if let price = price(value) {
            let selected = term == value
            Button {
                term = value
            } label: {
                VStack(spacing: 2) {
                    Text(title(value)).font(.body.weight(.semibold))
                    Text(price).font(.body).monospacedDigit()
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(selected ? Color.accentColor : .primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
        }
    }
}

// MARK: - 비교표

/// 세 칸이 무엇을 주는지 한눈에 (요청서의 표 그대로).
struct PlanComparisonTable: View {
    private enum Cell { case yes, no, text(String) }

    private struct Line: Identifiable {
        let title: String
        let free: Cell, plus: Cell, pro: Cell
        var id: String { title }
    }

    private var lines: [Line] {
        let unlimited = Cell.text(L("plan.table.unlimited"))
        let trial = Cell.text(L("plan.table.remoteTrial", PlanEntitlement.freeRemoteTalks))
        return [
            Line(title: L("plan.table.notes"), free: .text(L("plan.table.notesFree", PlanEntitlement.freeNotes)), plus: unlimited, pro: unlimited),
            Line(title: L("plan.table.timers"), free: .text(L("plan.table.timersFree", PlanEntitlement.freeTimers)), plus: unlimited, pro: unlimited),
            Line(title: L("plan.table.pomodoro"), free: .yes, plus: .yes, pro: .yes),
            Line(title: L("plan.table.teleprompter"), free: .yes, plus: .yes, pro: .yes),
            Line(title: L("plan.table.hotkeys"), free: .yes, plus: .yes, pro: .yes),
            Line(title: L("plan.table.themes"), free: .yes, plus: .yes, pro: .yes),
            Line(title: L("plan.table.chameleon"), free: .no, plus: .yes, pro: .yes),
            Line(title: L("plan.table.presets"), free: .no, plus: .yes, pro: .yes),
            Line(title: L("plan.table.music"), free: .no, plus: .yes, pro: .yes),
            Line(title: L("plan.table.mirror"), free: .no, plus: .yes, pro: .yes),
            Line(title: L("plan.table.remote"), free: trial, plus: trial, pro: .yes),
            Line(title: L("plan.table.timerWindow"), free: .no, plus: .no, pro: .yes),
            Line(title: L("plan.table.shortcuts"), free: .no, plus: .no, pro: .yes),
            Line(title: L("plan.table.widget"), free: .no, plus: .no, pro: .yes),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("plan.table.title"))
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Color.clear.frame(height: 1).gridCellUnsizedAxes([.horizontal, .vertical])
                    ForEach(PlanTier.allCases, id: \.self) { tier in
                        Text(tier.shortTitle)
                            .font(.body.weight(.semibold))
                            .gridColumnAlignment(.center)
                    }
                }
                ForEach(lines) { line in
                    Divider()
                    GridRow {
                        Text(line.title).font(.body).fixedSize(horizontal: false, vertical: true)
                        cellView(line.free, in: .free)
                        cellView(line.plus, in: .plus)
                        cellView(line.pro, in: .pro)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// 칸 하나. VoiceOver 는 어느 칸인지 함께 읽는다 ("Plus: 포함").
    @ViewBuilder
    private func cellView(_ cell: Cell, in tier: PlanTier) -> some View {
        switch cell {
        case .yes:
            Image(systemName: "checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel(Text(verbatim: "\(tier.shortTitle): \(L("plan.table.included"))"))
        case .no:
            Image(systemName: "minus")
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text(verbatim: "\(tier.shortTitle): \(L("plan.table.notIncluded"))"))
        case .text(let text):
            Text(text).font(.body).monospacedDigit()
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(verbatim: "\(tier.shortTitle): \(text)"))
        }
    }
}
