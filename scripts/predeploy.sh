#!/bin/bash
#
# 배포 전 검사 — 실패하면 0이 아닌 값으로 끝나 아카이브를 막는다.
#
# 테스트 타겟(StickyPresenterTests)은 순수 로직만 본다 — 타이머 입력 해석·벽시계 틱,
# 노트 저장 형식·깨진 파일 복구·화면 자리 계산. 창·메뉴·리모컨 동작은 여전히 손으로 확인한다.
#
# Release 로 짓는 이유: 배포는 Release 로 나가고, #if DEBUG 안에만 있는 코드를 밖에서
# 부르면 Debug 만 통과하고 Release 에서 깨진다.
#
# 서명은 끈다. 여기서 보는 것은 컴파일이고, 서명·공증은 DeployBar 의 아카이브가 한다.

set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="StickyPresenter.xcodeproj"
SCHEME="StickyPresenter"

echo "🔍 배포 전 검사 — $SCHEME (Release, macOS)"

# 1) 버전이 Config/Version.xcconfig 한 곳에서 오는지.
#    앱 Info.plist 에 숫자를 박거나 project.yml 타겟 설정에 MARKETING_VERSION 을 다시 넣으면
#    앱과 위젯 버전이 갈라지고, 임베드 익스텐션 버전 불일치로 App Store 가 업로드를 거절한다.
for plist in StickyPresenter/Info.plist Widget/Info.plist; do
  for key in CFBundleShortVersionString CFBundleVersion; do
    val="$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist")"
    case "$val" in
      '$(MARKETING_VERSION)'|'$(CURRENT_PROJECT_VERSION)') ;;
      *) echo "❌ $plist 의 $key 가 '$val' 로 박혀 있습니다 — \$(MARKETING_VERSION)/\$(CURRENT_PROJECT_VERSION) 을 쓰세요"; exit 1 ;;
    esac
  done
done
if grep -Eq '^\s*(MARKETING_VERSION|CURRENT_PROJECT_VERSION)\s*=' "$PROJECT/project.pbxproj"; then
  echo "❌ project.pbxproj 에 버전이 직접 적혀 있어 Config/Version.xcconfig 를 가립니다"
  grep -nE '^\s*(MARKETING_VERSION|CURRENT_PROJECT_VERSION)\s*=' "$PROJECT/project.pbxproj"
  exit 1
fi

# 2) Release 빌드.
#    판정은 xcodebuild 의 종료 코드 하나로 한다. 로그를 grep 해서 판단하면
#    경고 문구에 "error:" 가 섞여 들어올 때 멀쩡한 빌드를 실패로 읽는다.
LOG="$(mktemp -t predeploy)"
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
     -configuration Release -destination 'generic/platform=macOS' \
     CODE_SIGNING_ALLOWED=NO \
     -quiet build > "$LOG" 2>&1; then
  echo "❌ Release 빌드 실패"
  tail -40 "$LOG"
  rm -f "$LOG"
  exit 1
fi
rm -f "$LOG"

# 3) 단위 테스트. 노트 저장 형식이 깨지면 사용자 글이 사라지므로 배포를 막는다.
LOG="$(mktemp -t predeploy)"
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
     -destination 'platform=macOS' \
     CODE_SIGNING_ALLOWED=NO \
     -quiet test > "$LOG" 2>&1; then
  echo "❌ 단위 테스트 실패"
  grep -E "error:|failed" "$LOG" | tail -40
  rm -f "$LOG"
  exit 1
fi
rm -f "$LOG"

echo "✅ Release 빌드 · 단위 테스트 통과"
