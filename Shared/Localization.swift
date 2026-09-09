import Foundation

/// `NSLocalizedString` 을 짧게 감싼 것.
///
/// 앱 본체와 위젯이 함께 컴파일하지만, `Bundle.main` 은 각 번들을 가리키므로
/// 두 타깃이 각자의 `Localizable.strings` 를 본다.
///
/// SwiftUI 의 `Text("literal")` 은 스스로 지역화하므로 그대로 두고,
/// 이 함수는 **AppKit 문자열과 서식이 필요한 문자열**에만 쓴다.
/// 계산된 `String` 을 `Text`/`.help` 에 넘기면 SwiftUI 가 다시 찾지 않으므로
/// 이중 지역화 걱정도 없다.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return args.isEmpty ? format : String(format: format, arguments: args)
}
