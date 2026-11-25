#!/bin/zsh
# 심사용 실기기 화면 녹화 — USB 로 붙은 iPhone 에서 앱을 새로 깔고, UI 테스트가 주 흐름을 돌고, 그 화면을 녹화한다.
# 쓰는 법: Mac 에서 StickyPresenter 를 켜 두고(같은 Wi‑Fi) →  ./record.sh <기기 UDID> <앱 .app 경로> <출력.mov>
#   PAIR_CODE 는 Mac 의 `defaults read com.leeo.StickyPresenter remote.pairingCode`, MAC_PREFIX 는 Mac 이름 앞부분.
# 처음 한 번은 macOS 가 '터미널 카메라 접근' 을 묻는다(USB iPhone 화면도 카메라로 본다) — 사람이 [허용].
# 결과물의 홈 화면 위젯 · 로컬 네트워크 허용 창 지도는 개인정보라 올리기 전에 ffmpeg boxblur 로 가린다(docs/review 커밋 참고).
set -u
U=$1; A=$2; OUT=$3; HERE=${0:A:h}
cd $HERE
[[ -x ./rec ]] || swiftc -O rec.swift -o rec
[[ -d ReviewDemo.xcodeproj ]] || xcodegen generate -q
xcodebuild build-for-testing -project ReviewDemo.xcodeproj -scheme ReviewDemo -destination "id=$U" -allowProvisioningUpdates -quiet || exit 1
xcrun devicectl device uninstall app --device $U com.leeo.StickyPresenter >/dev/null 2>&1
xcrun devicectl device install app --device $U $A >/dev/null || exit 1
./rec $OUT & R=$!
sleep 5
TEST_RUNNER_PAIR_CODE=$(defaults read com.leeo.StickyPresenter remote.pairingCode) \
  xcodebuild test-without-building -project ReviewDemo.xcodeproj -scheme ReviewDemo -destination "id=$U"; T=$?
sleep 3; kill -INT $R; wait $R
exit $T
