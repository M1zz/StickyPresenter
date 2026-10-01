#!/bin/bash
#
# 배포 전 검사 — 리모컨 앱(iPhone). 실패하면 0이 아닌 값으로 끝나 아카이브를 막는다.
#
# 테스트 타겟이 없어 Release 컴파일만 본다. 배포는 Release 로 나가고, #if DEBUG 안에만 있는
# 코드를 밖에서 부르면 Debug 만 통과하고 Release 에서 깨진다. 서명은 끈다 — 서명은 DeployBar 의 아카이브가 한다.
#
# 리모컨은 ../Shared/RemoteProtocol.swift 를 Mac 앱과 같이 쓴다. 한쪽만 고쳐 프로토콜이 어긋나면
# 컴파일은 되어도 짝이 안 맞으므로, 두 앱을 같은 날 함께 출시한다.

set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="StickyPresenterRemote.xcodeproj"
SCHEME="StickyPresenterRemote"

echo "🔍 배포 전 검사 — $SCHEME (Release, iOS)"

# 버전이 Config/Version.xcconfig 한 곳에서 오는지 — project.yml 이나 Info.plist 에 숫자가 박히면 이 파일이 무시된다
if grep -nE '^\s*(MARKETING_VERSION|CURRENT_PROJECT_VERSION):' project.yml; then
  echo "❌ project.yml 에 버전 숫자가 있습니다 — Config/Version.xcconfig 로 옮기세요"; exit 1
fi

xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build -quiet

echo "✅ 배포 전 검사 통과"
