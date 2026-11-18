import LeeoKit
import StoreKit
import SwiftUI

// MARK: - 페이월
//
// 잠긴 조작을 누르거나 설정 ▸ Pro 둘러보기에서 연다. 위에 무료와 Pro 를 견주는 표,
// 아래에 고르는 길: 연 구독(기본) · 평생, 펼치면 월 · 주.
// 스토어에서 불러온 상품만 보인다 — 아직 없는 상품의 단추가 깨진 채 서지 않게.

struct RemotePaywallView: View {
    /// 방금 누른 잠긴 조작. 표에서 그 줄을 짚어 준다.
    var feature: RemoteProFeature?

    @ObservedObject private var pro = RemotePro.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selected = RemoteProducts.yearly
    @State private var showsShortTerms = false
    @State private var introEligible = false

    private var store: LeeoStore { pro.store }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    comparison
                    plans
                    footer
                }
                .padding(20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .task {
            LeeoAnalyticsCenter.track(.paywallShown(reason: feature?.rawValue))
            await store.loadProducts()
            introEligible = await pro.product(RemoteProducts.yearly)?.subscription?.isEligibleForIntroOffer ?? false
        }
        .onChange(of: pro.hasPro) { _, has in if has { dismiss() } }
    }

    // MARK: 머리말

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: feature?.systemImage ?? "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
                .padding(.top, 8)
            Text(verbatim: "StickyPresenter Pro")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("발표를 넘기는 조작은 언제나 무료예요. 타이머 창을 꾸미고 옮기고, 손목으로 남은 시간을 받고 싶을 때 Pro를 고르세요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Mac의 StickyPresenter와 같은 Pro예요. 한 번 열면 Mac에서도 열려요.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 비교표

    private struct Row: Identifiable {
        let title: String
        let free: Bool
        var feature: RemoteProFeature?
        var id: String { title }
    }

    private var rows: [Row] {
        [Row(title: String(localized: "연결 · 시작 · 멈춤 · 30초 조정 · 초기화"), free: true),
         Row(title: String(localized: "새 타이머 · Siri · 단축어"), free: true),
         Row(title: String(localized: "감추기 · 정렬 · 지우기"), free: true)]
        + RemoteProFeature.allCases.map { Row(title: $0.title, free: false, feature: $0) }
    }

    private var comparison: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Color.clear.frame(height: 1).gridCellUnsizedAxes([.horizontal, .vertical])
                Text("무료").font(.body.weight(.semibold)).foregroundStyle(.secondary)
                    .gridColumnAlignment(.center)
                Text(verbatim: "Pro").font(.body.weight(.semibold)).foregroundStyle(.tint)
                    .gridColumnAlignment(.center)
            }
            .accessibilityHidden(true)
            ForEach(rows) { row in
                Divider()
                GridRow {
                    Text(row.title)
                        .font(row.feature == feature && feature != nil ? .body.weight(.semibold) : .body)
                        .fixedSize(horizontal: false, vertical: true)
                    mark(row.free)
                    mark(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.title)
                .accessibilityValue(row.free ? String(localized: "무료로 쓸 수 있어요") : String(localized: "Pro에서 열려요"))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func mark(_ on: Bool) -> some View {
        Image(systemName: on ? "checkmark" : "minus")
            .font(.body.weight(on ? .bold : .regular))
            .foregroundStyle(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            .frame(minWidth: 36)
    }

    // MARK: 고르기

    /// 기간 하나. 스토어에서 불러온 것만 선다.
    private struct Plan: Identifiable {
        let product: Product
        let title: String
        let price: String
        let note: String?
        var id: String { product.id }
    }

    private var mainPlans: [Plan] {
        var plans: [Plan] = []
        let yearly = pro.product(RemoteProducts.yearly)
        if let yearly {
            plans.append(Plan(product: yearly, title: LeeoLadderText.yearly,
                              price: String(format: LeeoLadderText.perYearFormat, yearly.displayPrice),
                              note: introNote(yearly)))
        }
        if let lifetime = pro.product(pro.lifetimeProductID) {
            plans.append(Plan(product: lifetime, title: LeeoLadderText.lifetime, price: lifetime.displayPrice,
                              note: worthNote(yearly: yearly, lifetime: lifetime)))
        }
        return plans
    }

    private var shortPlans: [Plan] {
        var plans: [Plan] = []
        if let monthly = pro.product(RemoteProducts.monthly) {
            plans.append(Plan(product: monthly, title: String(localized: "월 구독"),
                              price: String(localized: "\(monthly.displayPrice) / 월"), note: nil))
        }
        if let weekly = pro.product(RemoteProducts.weekly) {
            plans.append(Plan(product: weekly, title: String(localized: "주 구독"),
                              price: String(localized: "\(weekly.displayPrice) / 주"), note: nil))
        }
        return plans
    }

    @ViewBuilder
    private var plans: some View {
        let main = mainPlans, short = shortPlans
        if main.isEmpty && short.isEmpty {
            if store.isLoadingProducts {
                ProgressView().padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    Text("상품을 불러오지 못했어요.")
                        .foregroundStyle(.secondary)
                    Button("다시 시도") { Task { await store.loadProducts() } }
                }
                .padding(.vertical, 16)
            }
        } else {
            VStack(spacing: 10) {
                ForEach(main) { planRow($0) }
                if !short.isEmpty {
                    DisclosureGroup(isExpanded: $showsShortTerms) {
                        VStack(spacing: 10) {
                            ForEach(short) { planRow($0) }
                        }
                        .padding(.top, 10)
                    } label: {
                        Text("다른 기간 보기")
                            .font(.body)
                    }
                    .padding(.horizontal, 4)
                }
                buyButton
                if let error = store.lastError {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .onAppear { if pro.product(selected) == nil { selected = (main + short).first?.id ?? selected } }
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        let isSelected = selected == plan.id
        return Button {
            selected = plan.id
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title).font(.headline)
                    // 아주 큰 글자에서는 가격을 이름 아래로 내린다.
                    if typeSize.isAccessibilitySize { Text(plan.price).font(.body).monospacedDigit() }
                    if let note = plan.note {
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if !typeSize.isAccessibilitySize { Text(plan.price).font(.body).monospacedDigit() }
            }
            .foregroundStyle(.primary)
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var buyButton: some View {
        Button {
            guard let product = pro.product(selected) else { return }
            Task {
                if await store.purchase(product, using: { try await purchase($0) }) {
                    await pro.didPurchase()
                }
            }
        } label: {
            Group {
                if store.purchasingProductID != nil {
                    ProgressView().tint(.white)
                } else {
                    Text("Pro 열기").font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(pro.product(selected) == nil || store.purchasingProductID != nil)
        .accessibilityLabel(String(localized: "Pro 열기"))
        .padding(.top, 4)
    }

    private func introNote(_ yearly: Product) -> String? {
        guard introEligible, let offer = yearly.subscription?.introductoryOffer,
              offer.paymentMode == .payUpFront || offer.paymentMode == .payAsYouGo else { return nil }
        return String(format: LeeoLadderText.introFormat, offer.displayPrice)
    }

    /// "연 구독 N년치, 한 번만 내면 끝". 2년치가 안 되면 말하지 않는다.
    private func worthNote(yearly: Product?, lifetime: Product) -> String? {
        guard let yearly, yearly.price > 0 else { return nil }
        let years = Int(NSDecimalNumber(decimal: lifetime.price / yearly.price).doubleValue.rounded(.down))
        return years >= 2 ? String(format: LeeoLadderText.lifetimeWorthFormat, years) : nil
    }

    // MARK: 아래

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Task { await store.restore(); await pro.didPurchase() }
            } label: {
                if store.isRestoring { ProgressView() } else { Text("구매 복원") }
            }
            .disabled(store.isRestoring)

            Text("결제는 App Store 계정으로 청구됩니다. 구독은 언제든지 App Store 설정에서 관리·해지할 수 있어요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                if let terms = store.config.termsURL { Link("이용약관", destination: terms) }
                Link("개인정보처리방침", destination: RemoteSpec.legal.privacyURL)
            }
            .font(.body)
        }
    }
}
