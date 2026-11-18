#!/bin/sh
# Apple Watch 스토어 스크린샷을 언어마다 찍는다 — 워치 앱이 스스로 장면을 띄우는 디버그 인자(-watchDemo)를 쓴다.
# Mac · iPhone 과 붙이지 않아도 남은 시간이 찬다(Watch/WatchDemo.swift, DEBUG 전용).
#
# 사용법: scripts/make_watch_screenshots.sh <워치 시뮬레이터 UDID> [로케일 ...]   (Apple Watch 46mm — 416x496)
#   미리: Debug 빌드의 StickyPresenterRemoteWatch.app 을 그 시뮬레이터에 설치한다.
#   결과: docs/screenshots/watch/<로케일>/01-running.png · 02-paused.png (원본이 곧 제출본)
#
# ⚠️ 알림 권한 창이 떠 있으면 화면을 가린다. 데모에서는 권한을 묻지 않지만, 부팅 중에 앱을 띄우면
#    시스템이 인자 없이 다시 띄워 창이 남을 수 있다 — 그러면 시뮬레이터를 껐다 켜고 다시 찍는다.
set -e
U=$1; shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE=com.leeo.StickyPresenter.watchkitapp
LOCALES=${*:-"ko en-US en-GB ja zh-Hans zh-Hant es de fr it pt-BR ru th vi cs da el fi id nb nl pl sv tr"}

cap() {  # cap <로케일> <파일> <장면>
  L=$1; OUT=$2; SCENE=$3
  xcrun simctl terminate "$U" $BUNDLE >/dev/null 2>&1 || true
  xcrun simctl launch "$U" $BUNDLE -AppleLanguages "($L)" -AppleLocale "$(echo "$L" | tr - _)" -watchDemo "$SCENE" >/dev/null
  sleep "${WAIT:-4}"
  xcrun simctl io "$U" screenshot "$OUT" >/dev/null 2>&1
}

for L in $LOCALES; do
  W="$ROOT/docs/screenshots/watch/$L"; mkdir -p "$W"
  cap "$L" "$W/01-running.png" running
  cap "$L" "$W/02-paused.png"  paused
  echo "done $L"
done
xcrun simctl terminate "$U" $BUNDLE >/dev/null 2>&1 || true
