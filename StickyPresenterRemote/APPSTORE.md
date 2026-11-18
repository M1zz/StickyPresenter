# Remote Controller — App Store 문구

DeployBar 가 배포할 때 이 파일을 읽어 리모컨 앱(StickyPresenterRemote)의 App Store 페이지에 올린다.
Mac 앱 문구는 레포 최상단 `APPSTORE.md` 에 따로 있다.
기능은 `docs/remote.html` 과 `Sources/` 에 있는 것만 쓴다 — 리모컨은 타이머만 다룬다(슬라이드 넘기기는 없다).

<!-- ⚠️ 이 앱은 Mac 'StickyPresenter' 와 같은 App Store 레코드의 iPhone · Watch 판이다 (번들 ID com.leeo.StickyPresenter).
     이름 · 부제 · 개인정보 처리방침 URL 은 레코드 하나에 하나뿐이라 Mac 레포의 APPSTORE.md 와 글자 하나까지 같게 둔다.
     여기서 다르게 적으면 배포가 Mac 쪽 이름까지 바꾼다. iPhone 에서만 다른 것은 설명 · 키워드 · 프로모션 텍스트 · 지원 URL · 스크린샷이다. -->

## 한국어 (ko)

### 이름

StickyPresenter

### 부제

발표 화면 위 메모와 타이머

### 키워드

프레젠터,진행자,발표리모컨,강의타이머,발표자,큐시트,발표연습,스티키,프레젠테이션리모컨,스피치타이머,프롬프터,발표대본,발표도우미,슬라이드넘기기,리허설

### 프로모션 텍스트

Mac은 저 멀리 있어도 괜찮아요. 타이머 시작·일시정지, 30초 더하기, 슬라이드를 가린 타이머 비켜 놓기까지 iPhone에서 바로 합니다.

### 설명

StickyPresenterRemote는 Mac용 StickyPresenter의 iPhone 리모컨입니다. 발표 중 손이 닿지 않는 Mac 대신, 타이머 조작을 손안으로 가져옵니다.

혼자 쓰는 앱이 아닙니다. 같은 Wi-Fi에 있는 Mac에서 StickyPresenter가 실행 중이어야 합니다.

할 수 있는 것
• 남은 시간 보기 — 남은 시간과 진행률, 뽀모도로 집중·휴식 구간과 몇 번째 사이클인지 1초마다 보여 줍니다
• 시작, 일시정지, 초기화
• 이야기가 길어지면 그 자리에서 30초 더하기·빼기
• 3분, 5분, 10분, 15분 프리셋으로 새 타이머 시작
• 위젯 크기를 S, M, L로 바꿔 뒷자리에서도 읽히게
• Mac 화면 배치를 줄여 그린 판에서 끌어 위젯 옮기기 — 슬라이드를 가리면 Mac에 손대지 않고 비켜 놓고, 확장 디스플레이가 있으면 옆 화면으로 넘깁니다
• 청중에게서 위젯 감추기, 놓친 위젯 패널 옆으로 불러오기, 타이머 지우기

Apple Watch
발표 중에는 화면을 들여다볼 틈이 없습니다. Apple Watch에 남은 시간이 크게 보이고, 5분과 1분 남았을 때, 그리고 끝날 때 손목이 울립니다. 재생 버튼으로 시작·일시정지하고, Digital Crown을 한 칸 돌릴 때마다 30초씩 더하거나 뺍니다. 지원하는 모델에서는 손가락 두 번 두드리기로도 시작·일시정지하고, 단축어로 Apple Watch Ultra의 동작 버튼에 걸어 둘 수 있습니다. 시계 화면에 컴플리케이션을 두면 손목만 들어도 남은 시간이 보입니다. 워치는 이 iPhone 리모컨을 거쳐 Mac에 닿으므로 조작하려면 iPhone에서 리모컨이 열려 있어야 합니다. iPhone이 잠겨도 남은 시간과 진동은 워치가 혼자 이어 갑니다.

연결 방식
두 앱은 로컬 네트워크에서 서로를 찾아 직접 주고받습니다. 만들 계정도, 중간에 거치는 서버도 없고, 인터넷으로 나가는 통신도 없습니다.

연결 코드는 처음 한 번만 넣습니다. 앱을 열고 목록에서 내 Mac을 고른 뒤, Mac 메뉴 막대의 타이머 아이콘 → Remote에 뜬 네 자리 코드를 입력하세요. 그다음부터는 앱만 열면 그 Mac에 저절로 붙습니다. 같은 Wi-Fi에 Mac이 여러 대 있어도 리모컨은 짝을 맺은 Mac 한 대에만 붙습니다.

Mac을 찾지 못하면 흔한 원인을 체크리스트로 보여 줍니다.

개인정보
계정, 분석, 추적, 광고가 없습니다. 주고받는 것은 타이머 정보와 내가 누른 명령뿐이고, 짝을 맺은 Mac하고만 주고받습니다. 스티키 노트와 프롬프터 원고는 iPhone으로 보내지 않습니다.

준비물
• iOS 17 이상의 iPhone
• 같은 Wi-Fi에서 StickyPresenter가 실행 중인 Mac
• 두 기기 모두 로컬 네트워크 접근 허용

구독 안내
StickyPresenterRemote Pro 구독은 자동 갱신 구독입니다. 갱신일 24시간 전까지 해지하지 않으면 Apple 계정으로 자동 결제되며, 설정의 구독 관리에서 언제든 해지할 수 있습니다.
이용약관(EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
개인정보처리방침: https://m1zz.github.io/StickyPresenter/ko/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/ko/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/ko/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/ko/remote.html

## 영어(미국) (en-US)

### 이름

StickyPresenter

### 부제

Notes & timers for your talk

### 키워드

presenter,countdown,speech,pomodoro,stopwatch,companion,rehearsal,lecture,meeting,seminar,speaker

### 프로모션 텍스트

Your Mac is across the room. Start, pause, add 30 seconds, or move the timer off a slide — from your iPhone, over your own Wi-Fi.

### 설명

StickyPresenterRemote is the iPhone companion to StickyPresenter for Mac. While you present, your Mac is out of reach — this puts the timer controls in your hand.

This is not a standalone app. It needs StickyPresenter running on a Mac on the same Wi-Fi network.

WHAT YOU CAN DO
• See the countdown — remaining time, progress, and the Pomodoro phase with its cycle number, updated every second
• Start, pause, and reset
• Add or subtract 30 seconds when a section runs long
• Start a new timer from 3, 5, 10, and 15 minute presets
• Resize the widget — S, M, or L — so it reads from the back of the room
• Move the widget by dragging it on a miniature of your Mac's screen layout. If it covers a slide, move it off without touching your Mac. With a second display, drag it across to the other screen.
• Hide the widget from your audience, pull a lost one back next to the panel, or delete the timer

APPLE WATCH
While you present, there is no time to keep checking a screen. Apple Watch shows the time left in large type and taps your wrist at 5 minutes, at 1 minute, and when time is up. Start or pause with the play button, and turn the Digital Crown one notch to add or subtract 30 seconds. On supported models a double tap also starts or pauses, and with Shortcuts you can put it on the Action button of Apple Watch Ultra. Add the complication to your watch face to see the time left with a raise of the wrist. The watch reaches your Mac through this iPhone remote, so keep the remote open on your iPhone to control the timer. If your iPhone locks, the watch keeps counting and tapping on its own.

HOW IT CONNECTS
The two apps find each other over your local network and talk directly, with no account to create and no server in the middle. Nothing is sent over the internet.

You enter a code only once. Open the app, pick your Mac from the list, and type the four-digit code shown on the Mac under menu bar timer icon → Remote. From then on it connects on its own whenever you open it. In a room where several Macs are running StickyPresenter, the remote only ever reaches the one it is paired with.

If it can't find your Mac, the app shows a checklist of the usual causes.

PRIVACY
No account, no analytics, no tracking, no ads. Only timer information and the commands you tap are exchanged, and only with your paired Mac. Your sticky notes and teleprompter scripts are never sent to the iPhone.

REQUIREMENTS
• iPhone with iOS 17 or later
• A Mac running StickyPresenter on the same Wi-Fi network
• Local Network permission allowed on both devices

Subscriptions
StickyPresenterRemote Pro is an auto-renewing subscription. Payment is charged to your Apple Account, and the subscription renews unless canceled at least 24 hours before the current period ends. Manage or cancel anytime in Settings.
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://m1zz.github.io/StickyPresenter/en/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/en/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/en/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/en/remote.html

## 영어(영국) (en-GB)

### 이름

StickyPresenter

### 부제

Notes & timers for presenting

### 키워드

countdown,speech,pomodoro,stopwatch,companion,rehearsal,lecture,meeting,seminar,speaker,classroom

### 프로모션 텍스트

Your Mac is on the other side of the room. Start, pause, add 30 seconds or move the timer off a slide, straight from your iPhone over your own Wi-Fi.

### 설명

StickyPresenterRemote is the iPhone companion to StickyPresenter for Mac. When you are presenting, your Mac is usually out of reach. This puts the timer controls in your hand.

It is not a standalone app. It needs StickyPresenter running on a Mac on the same Wi-Fi network.

WHAT YOU CAN DO
• See the countdown: time remaining, progress, and the Pomodoro phase with its cycle number, refreshed every second
• Start, pause and reset
• Add or subtract 30 seconds when a section overruns
• Start a new timer from 3, 5, 10 and 15 minute presets
• Change the widget size to S, M or L so it can be read from the back of the room
• Move the widget by dragging it on a miniature of your Mac's screen layout. If it is covering a slide, shift it out of the way without going near your Mac. With a second display, drag it across to the other screen.
• Hide the widget from your audience, bring a lost one back beside the panel, or delete the timer

APPLE WATCH
While you present, there is no time to keep checking a screen. Apple Watch shows the time left in large type and taps your wrist at 5 minutes, at 1 minute, and when time is up. Start or pause with the play button, and turn the Digital Crown one notch to add or subtract 30 seconds. On supported models a double tap also starts or pauses, and with Shortcuts you can put it on the Action button of Apple Watch Ultra. Add the complication to your watch face to see the time left with a raise of the wrist. The watch reaches your Mac through this iPhone remote, so keep the remote open on your iPhone to control the timer. If your iPhone locks, the watch keeps counting and tapping on its own.

HOW IT CONNECTS
The two apps find each other on your local network and talk directly. There is no account to create and no server in between, and nothing is sent over the internet.

You only enter a code once. Open the app, choose your Mac from the list and type the four-digit pairing code shown under the timer icon → Remote in the Mac's menu bar. After that, it connects by itself whenever you open it. In a room where several Macs are running StickyPresenter, the remote only ever talks to the one it is paired with.

If it cannot find your Mac, the app shows a checklist of the usual causes.

PRIVACY
No account, no analytics, no tracking and no adverts. Only timer information and the commands you tap are exchanged, and only with your paired Mac. Your sticky notes and teleprompter scripts are never sent to the iPhone.

REQUIREMENTS
• iPhone with iOS 17 or later
• A Mac running StickyPresenter on the same Wi-Fi network
• Local Network access allowed on both devices

Subscriptions
StickyPresenterRemote Pro is an auto-renewing subscription. Payment is charged to your Apple Account, and the subscription renews unless cancelled at least 24 hours before the current period ends. Manage or cancel any time in Settings.
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://m1zz.github.io/StickyPresenter/en/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/en/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/en/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/en/remote.html

## 日本語 (ja)

### 이름

StickyPresenter

### 부제

発表中の原稿とタイマーを前面に

### 키워드

リモコン,プレゼン,カウントダウン,ポモドーロ,ストップウォッチ,講演,講義,授業,会議,セミナー,スピーチ,司会,講師,研修,時間管理,遠隔,ワイヤレス,学会,リハーサル,勉強会,タイムキーパー

### 프로모션 텍스트

Macが離れた場所にあっても大丈夫。タイマーの開始・一時停止、30秒の追加、スライドに重なったタイマーの移動まで、iPhoneからすぐに操作できます。

### 설명

StickyPresenterRemoteは、Mac用アプリStickyPresenterのiPhoneリモコンです。発表中は手が届かないMacの代わりに、タイマーの操作を手元に持ってきます。

単体では使えません。同じWi-FiにつながっているMacでStickyPresenterが起動している必要があります。

できること
• 残り時間の確認：残り時間と進み具合、ポモドーロの集中・休憩と何サイクル目かを1秒ごとに表示
• 開始、一時停止、リセット
• 話が延びたら、その場で30秒増やす・減らす
• 3分、5分、10分、15分のプリセットで新しいタイマーを開始
• ウィジェットのサイズをS、M、Lに切り替えて、後ろの席からも読みやすく
• Macの画面配置を縮小したパッド上でドラッグしてウィジェットを移動。スライドに重なってもMacに触れずによけられ、外部ディスプレイがあれば隣の画面へ移せます
• 聴衆からウィジェットを隠す、見失ったウィジェットをパネルの横に呼び戻す、タイマーを削除する

Apple Watchで
発表中は画面を見る余裕がありません。Apple Watchに残り時間を大きく表示し、残り5分と1分、そして終了時に手首を振動で知らせます。再生ボタンで開始・一時停止、Digital Crownを1段回すごとに30秒増やしたり減らしたりできます。対応モデルではダブルタップでも開始・一時停止でき、ショートカットを使えばApple Watch Ultraのアクションボタンにも割り当てられます。文字盤にコンプリケーションを置けば、手首を上げるだけで残り時間がわかります。WatchはこのiPhoneリモコンを通じてMacにつながるため、操作するにはiPhoneでリモコンを開いておく必要があります。iPhoneがロックされても、残り時間の表示と振動はWatchだけで続きます。

接続のしくみ
2つのアプリはローカルネットワーク上でお互いを見つけ、直接やり取りします。アカウント登録も、間に入るサーバもなく、インターネットへの通信もありません。

ペアリングコードの入力は最初の1回だけです。アプリを開いて一覧から自分のMacを選び、Macのメニューバーにあるタイマーアイコン →「リモコン」に表示される4桁のコードを入力してください。次回からはアプリを開くだけで、そのMacに自動でつながります。同じWi-FiにStickyPresenterを起動したMacが何台あっても、リモコンがつながるのはペアリングした1台だけです。

Macが見つからないときは、よくある原因をチェックリストで表示します。

プライバシー
アカウント、分析、トラッキング、広告はありません。やり取りするのはタイマーの情報と操作したコマンドだけで、相手はペアリングしたMacだけです。付箋メモやプロンプターの原稿がiPhoneに送られることはありません。

動作環境
• iOS 17以降のiPhone
• 同じWi-FiでStickyPresenterが起動しているMac
• 両方のデバイスでローカルネットワークへのアクセスを許可

サブスクリプションについて
StickyPresenterRemote Pro は自動更新のサブスクリプションです。 期間終了の24時間前までに解約しない限り、Apple Account に自動で請求され更新されます。設定のサブスクリプション管理からいつでも解約できます。
利用規約（EULA）: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
プライバシーポリシー: https://m1zz.github.io/StickyPresenter/ja/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/ja/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/ja/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/ja/remote.html

## 简体中文 (zh-Hans)

### 이름

StickyPresenter

### 부제

演讲便签、倒计时与提词器

### 키워드

遥控器,倒数,番茄钟,秒表,演示,汇报,讲座,上课,会议,研讨会,主持,时间管理,答辩,路演,讲师,培训,幻灯片,无线,发言,彩排,番茄工作法,专注,课堂,讲课,时钟,提醒,面试,学习,大屏幕

### 프로모션 텍스트

Mac 离你再远也没关系。开始、暂停、加 30 秒，或者把挡住幻灯片的计时器挪开，在 iPhone 上一点就行。

### 설명

StickyPresenterRemote 是 Mac 版 StickyPresenter 的 iPhone 遥控器。演讲时 Mac 往往够不着，它把计时器的操作交到你手里。

它不能单独使用，需要同一 Wi-Fi 下有一台正在运行 StickyPresenter 的 Mac。

可以做什么
• 查看倒计时：每秒更新剩余时间和进度，以及番茄钟当前是专注还是休息、第几轮
• 开始、暂停、重置
• 讲得超时了，随时增加或减少 30 秒
• 用 3、5、10、15 分钟预设开始新的计时器
• 把小组件大小切换为 S、M、L，坐在最后一排也看得清
• 在按比例缩小的 Mac 屏幕布局上拖动，移动小组件。挡住幻灯片时不用碰 Mac 就能挪开；接了扩展显示器，还能拖到另一块屏幕上
• 对观众隐藏小组件，把找不到的小组件召回到面板旁边，或删除计时器

Apple Watch
演讲时没空一直盯着屏幕。Apple Watch 会用大字显示剩余时间，并在剩 5 分钟、剩 1 分钟和时间到时轻敲你的手腕。按播放按钮开始或暂停，转动数码表冠一格即可增加或减少 30 秒。在支持的机型上还可以用双指互点两下开始或暂停，借助快捷指令也能把它设到 Apple Watch Ultra 的操作按钮上。把复杂功能放到表盘上，抬腕就能看到剩余时间。手表通过这台 iPhone 遥控器连接 Mac，所以要操控时请在 iPhone 上保持遥控器打开。即使 iPhone 锁屏，手表也会继续倒计时并按时振动。

连接方式
两个 App 在本地网络中互相发现并直接通信。不用注册账户，中间没有服务器，也不会通过互联网传输任何数据。

配对码只需输入一次。打开 App，在列表中选择你的 Mac，然后输入 Mac 菜单栏计时器图标 → 遥控器 中显示的 4 位配对码。之后只要打开 App，就会自动连接那台 Mac。即使同一 Wi-Fi 下有多台 Mac 在运行 StickyPresenter，遥控器也只会连接与它配对的那一台。

找不到 Mac 时，App 会以清单形式列出常见原因。

隐私
没有账户、分析、跟踪或广告。传输的只有计时器信息和你点按的指令，而且只在你与已配对的 Mac 之间传输。便签和提词器文稿永远不会发送到 iPhone。

使用要求
• 运行 iOS 17 或更高版本的 iPhone
• 同一 Wi-Fi 下正在运行 StickyPresenter 的 Mac
• 两台设备都允许访问本地网络

订阅说明
StickyPresenterRemote Pro 为自动续期订阅。 费用从你的 Apple 账户扣除，除非在当期结束前至少 24 小时取消，否则将自动续期。可随时在“设置”中管理或取消。
使用条款（EULA）: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
隐私政策: https://m1zz.github.io/StickyPresenter/zh-Hans/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/zh-Hans/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/zh-Hans/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/zh-Hans/remote.html

## 스페인어 (es)

### 이름

StickyPresenter

### 부제

Guion y cronómetro en pantalla

### 키워드

mando,distancia,temporizador,cuenta,atrás,cronómetro,pomodoro,presentación,ponente,orador,discurso

### 프로모션 텍스트

Aunque el Mac esté al otro lado de la sala: inicia, pausa, suma 30 segundos o aparta el temporizador de una diapositiva desde tu iPhone, por tu propia Wi-Fi.

### 설명

StickyPresenterRemote es el mando para iPhone de StickyPresenter para Mac. Mientras presentas, el Mac suele quedar lejos; esta app te pone los controles del temporizador en la mano.

No funciona por sí sola. Necesita StickyPresenter abierto en un Mac conectado a la misma red Wi-Fi.

QUÉ PUEDES HACER
• Ver la cuenta atrás: tiempo restante, progreso y la fase del Pomodoro con su número de ciclo, actualizados cada segundo
• Iniciar, pausar y restablecer
• Sumar o restar 30 segundos cuando una parte se alarga
• Iniciar un temporizador nuevo con los preajustes de 3, 5, 10 y 15 minutos
• Cambiar el tamaño del widget entre S, M y L para que se lea desde el fondo de la sala
• Mover el widget arrastrándolo sobre una miniatura de la disposición de pantallas del Mac. Si tapa una diapositiva, apártalo sin tocar el Mac. Con una segunda pantalla, pásalo a la otra.
• Ocultar el widget al público, traer uno perdido junto al panel o eliminar el temporizador

APPLE WATCH
Mientras presentas no hay tiempo para mirar pantallas. El Apple Watch muestra el tiempo restante en grande y te avisa con una vibración en la muñeca cuando quedan 5 minutos, cuando queda 1 y al terminar. Inicia o pausa con el botón de reproducción y gira la Digital Crown una muesca para sumar o restar 30 segundos. En los modelos compatibles también puedes iniciar o pausar con un doble toque, y con Atajos puedes asignarlo al botón de acción del Apple Watch Ultra. Añade la complicación a la esfera para ver el tiempo restante con solo levantar la muñeca. El reloj llega al Mac a través de este mando del iPhone, así que mantén el mando abierto en el iPhone para controlar el temporizador. Si el iPhone se bloquea, el reloj sigue contando y vibrando por su cuenta.

CÓMO SE CONECTA
Las dos apps se encuentran en tu red local y se comunican directamente. No hay que crear ninguna cuenta ni hay servidores de por medio, y no sale nada a internet.

El código solo se introduce una vez. Abre la app, elige tu Mac en la lista y escribe el código de vinculación de 4 dígitos que aparece en el icono del temporizador → Control remoto, en la barra de menús del Mac. A partir de ahí, se conecta solo cada vez que abres la app. Aunque en la sala haya varios Mac con StickyPresenter, el mando solo se conecta con el que está vinculado.

Si no encuentra tu Mac, la app te muestra una lista con las causas más habituales.

PRIVACIDAD
Sin cuentas, sin analíticas, sin rastreo y sin anuncios. Solo se intercambian los datos del temporizador y las órdenes que tocas, y solo con el Mac vinculado. Tus notas adhesivas y los guiones del teleprompter nunca se envían al iPhone.

REQUISITOS
• iPhone con iOS 17 o posterior
• Un Mac con StickyPresenter abierto en la misma red Wi-Fi
• Acceso a la red local permitido en ambos dispositivos

Suscripciones
La suscripción a StickyPresenterRemote Pro es de renovación automática. El cargo se realiza en tu cuenta de Apple y la suscripción se renueva salvo que la canceles al menos 24 horas antes de que termine el periodo. Puedes gestionarla o cancelarla cuando quieras en Ajustes.
Términos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://m1zz.github.io/StickyPresenter/es/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/es/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/es/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/es/remote.html

## Deutsch (de)

### 이름

StickyPresenter

### 부제

Notizen & Timer für Vorträge

### 키워드

Fernbedienung,Präsentation,Countdown,Stoppuhr,Redner,Pomodoro,Moderation,Rede,Seminar,Referat,Probe

### 프로모션 텍스트

Dein Mac steht am anderen Ende des Raums? Starte, pausiere, gib 30 Sekunden dazu oder schieb den Timer von der Folie, direkt vom iPhone über dein eigenes WLAN.

### 설명

StickyPresenterRemote ist die iPhone-Fernbedienung für StickyPresenter auf dem Mac. Während du präsentierst, ist dein Mac meist außer Reichweite. Mit dieser App hast du die Timer-Steuerung in der Hand.

Die App funktioniert nicht allein. Sie braucht StickyPresenter auf einem Mac im selben WLAN.

DAS KANNST DU TUN
• Countdown im Blick: verbleibende Zeit, Fortschritt und die Pomodoro-Phase mit Zyklusnummer, jede Sekunde aktualisiert
• Starten, pausieren und zurücksetzen
• 30 Sekunden hinzufügen oder abziehen, wenn ein Teil länger dauert
• Neuen Timer mit den Vorgaben 3, 5, 10 oder 15 Minuten starten
• Widget-Größe auf S, M oder L stellen, damit man es auch in der letzten Reihe liest
• Widget verschieben, indem du es auf einer Miniatur deiner Mac-Bildschirmanordnung ziehst. Verdeckt es eine Folie, schiebst du es weg, ohne den Mac anzufassen. Mit einem zweiten Display ziehst du es auf den anderen Bildschirm.
• Widget vor dem Publikum ausblenden, ein verlorenes neben das Panel zurückholen oder den Timer löschen

APPLE WATCH
Beim Präsentieren hast du keine Zeit, ständig auf einen Bildschirm zu schauen. Die Apple Watch zeigt die Restzeit groß an und tippt dir bei 5 Minuten, bei 1 Minute und am Ende aufs Handgelenk. Starten oder pausieren geht mit der Wiedergabetaste, und jede Raste der Digital Crown fügt 30 Sekunden hinzu oder zieht sie ab. Auf unterstützten Modellen startest oder pausierst du auch mit Doppeltippen, und über Kurzbefehle legst du es auf die Aktionstaste der Apple Watch Ultra. Leg die Komplikation aufs Zifferblatt, dann siehst du die Restzeit, sobald du das Handgelenk hebst. Die Uhr erreicht deinen Mac über diese iPhone-Fernbedienung. Lass die Fernbedienung auf dem iPhone also geöffnet, wenn du steuern willst. Sperrt sich das iPhone, zählt und vibriert die Uhr allein weiter.

SO VERBINDET SICH DIE APP
Die beiden Apps finden sich in deinem lokalen Netzwerk und sprechen direkt miteinander. Kein Konto, kein Server dazwischen, und nichts geht ins Internet.

Den Code gibst du nur einmal ein. Öffne die App, wähle deinen Mac aus der Liste und tippe den vierstelligen Kopplungscode ein, der in der Menüleiste des Macs unter Timer-Symbol → Fernbedienung steht. Danach verbindet sich die App von selbst, sobald du sie öffnest. Laufen im Raum mehrere Macs mit StickyPresenter, spricht die Fernbedienung trotzdem nur mit dem gekoppelten.

Findet die App deinen Mac nicht, zeigt sie eine Checkliste mit den häufigsten Ursachen.

DATENSCHUTZ
Kein Konto, keine Analyse, kein Tracking, keine Werbung. Ausgetauscht werden nur Timer-Informationen und die Befehle, die du tippst, und zwar nur mit deinem gekoppelten Mac. Deine Haftnotizen und Teleprompter-Skripte werden nie an das iPhone gesendet.

VORAUSSETZUNGEN
• iPhone mit iOS 17 oder neuer
• Ein Mac im selben WLAN, auf dem StickyPresenter läuft
• Zugriff auf das lokale Netzwerk auf beiden Geräten erlaubt

Abonnements
StickyPresenterRemote Pro ist ein sich automatisch verlängerndes Abo. Die Zahlung erfolgt über deinen Apple Account. Das Abo verlängert sich, sofern du nicht mindestens 24 Stunden vor Ablauf des Zeitraums kündigst. Verwalten oder kündigen kannst du jederzeit in den Einstellungen.
Nutzungsbedingungen (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutzerklärung: https://m1zz.github.io/StickyPresenter/de/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/de/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/de/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/de/remote.html

## 프랑스어 (fr)

### 이름

StickyPresenter

### 부제

Notes, minuteur et prompteur

### 키워드

télécommande,présentation,exposé,chronomètre,compte,rebours,pomodoro,conférence,orateur,discours

### 프로모션 텍스트

Votre Mac est à l’autre bout de la salle ? Lancez, mettez en pause, ajoutez 30 secondes ou écartez le minuteur d’une diapo depuis l’iPhone, via votre Wi-Fi.

### 설명

StickyPresenterRemote est la télécommande iPhone de StickyPresenter pour Mac. Pendant une présentation, votre Mac est souvent hors de portée : l’app vous met les commandes du minuteur dans la main.

Elle ne fonctionne pas seule. Il faut que StickyPresenter soit ouvert sur un Mac connecté au même réseau Wi-Fi.

CE QUE VOUS POUVEZ FAIRE
• Suivre le compte à rebours : temps restant, progression et phase Pomodoro avec le numéro du cycle, mis à jour chaque seconde
• Démarrer, mettre en pause et réinitialiser
• Ajouter ou retirer 30 secondes quand une partie déborde
• Lancer un nouveau minuteur avec les préréglages de 3, 5, 10 et 15 minutes
• Passer le widget en taille S, M ou L pour qu’on le lise depuis le fond de la salle
• Déplacer le widget en le faisant glisser sur une miniature de la disposition des écrans du Mac. S’il masque une diapo, écartez-le sans toucher au Mac. Avec un second écran, faites-le passer de l’autre côté.
• Masquer le widget au public, ramener un widget égaré à côté du panneau ou supprimer le minuteur

APPLE WATCH
Pendant une présentation, impossible de garder les yeux sur un écran. L’Apple Watch affiche le temps restant en grand et vous tapote le poignet à 5 minutes, à 1 minute et à la fin. Démarrez ou mettez en pause avec le bouton de lecture, et tournez la Digital Crown d’un cran pour ajouter ou retirer 30 secondes. Sur les modèles compatibles, un toucher double démarre ou met aussi en pause, et avec Raccourcis vous pouvez l’attribuer au bouton Action de l’Apple Watch Ultra. Ajoutez la complication au cadran pour voir le temps restant d’un simple geste du poignet. La montre rejoint votre Mac par cette télécommande iPhone : gardez donc la télécommande ouverte sur l’iPhone pour piloter le minuteur. Si l’iPhone se verrouille, la montre continue seule le décompte et les vibrations.

COMMENT ÇA SE CONNECTE
Les deux apps se trouvent sur votre réseau local et communiquent directement. Aucun compte à créer, aucun serveur intermédiaire, et rien ne passe par Internet.

Le code ne se saisit qu’une fois. Ouvrez l’app, choisissez votre Mac dans la liste et tapez le code d’appairage à 4 chiffres affiché sous l’icône du minuteur → Télécommande, dans la barre des menus du Mac. Ensuite, la connexion se fait toute seule à chaque ouverture. Même si plusieurs Mac de la salle font tourner StickyPresenter, la télécommande ne parle qu’à celui auquel elle est appairée.

Si votre Mac reste introuvable, l’app affiche une liste des causes les plus fréquentes.

CONFIDENTIALITÉ
Pas de compte, pas d’analyse, pas de suivi, pas de publicité. Seules les infos du minuteur et les commandes que vous touchez sont échangées, et uniquement avec le Mac appairé. Vos notes et les textes du prompteur ne sont jamais envoyés à l’iPhone.

CONFIGURATION REQUISE
• iPhone sous iOS 17 ou version ultérieure
• Un Mac sur le même réseau Wi-Fi avec StickyPresenter ouvert
• Accès au réseau local autorisé sur les deux appareils

Abonnements
L’abonnement StickyPresenterRemote Pro est à renouvellement automatique. Le paiement est débité sur votre compte Apple, et l’abonnement est reconduit sauf résiliation au moins 24 heures avant la fin de la période en cours. Gérez-le ou résiliez-le à tout moment dans Réglages.
Conditions d’utilisation (EULA) : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Politique de confidentialité : https://m1zz.github.io/StickyPresenter/fr/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/fr/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/fr/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/fr/remote.html

## 이탈리아어 (it)

### 이름

StickyPresenter

### 부제

Note, timer e gobbo

### 키워드

telecomando,presentazione,conto,rovescia,cronometro,pomodoro,relatore,discorso,conferenza,lezione

### 프로모션 텍스트

Il Mac è dall’altra parte della sala? Avvia, metti in pausa, aggiungi 30 secondi o sposta il timer da una slide direttamente dall’iPhone, sul tuo Wi-Fi.

### 설명

StickyPresenterRemote è il telecomando per iPhone di StickyPresenter per Mac. Mentre presenti, il Mac è spesso fuori portata: questa app ti mette i comandi del timer in mano.

Non funziona da sola. Serve StickyPresenter aperto su un Mac collegato alla stessa rete Wi-Fi.

COSA PUOI FARE
• Seguire il conto alla rovescia: tempo rimanente, avanzamento e fase Pomodoro con il numero del ciclo, aggiornati ogni secondo
• Avviare, mettere in pausa e ripristinare
• Aggiungere o togliere 30 secondi quando una parte si allunga
• Avviare un nuovo timer con i preset da 3, 5, 10 e 15 minuti
• Impostare il widget su S, M o L, così si legge anche dal fondo della sala
• Spostare il widget trascinandolo su una miniatura della disposizione degli schermi del Mac. Se copre una slide, lo sposti senza toccare il Mac. Con un secondo schermo, lo porti sull’altro.
• Nascondere il widget al pubblico, riportare accanto al pannello uno che hai perso di vista o eliminare il timer

APPLE WATCH
Mentre presenti non hai tempo di guardare uno schermo. Apple Watch mostra il tempo rimanente in grande e ti avvisa con un tocco al polso a 5 minuti, a 1 minuto e alla fine. Avvia o metti in pausa con il pulsante di riproduzione e ruota la Digital Crown di uno scatto per aggiungere o togliere 30 secondi. Sui modelli compatibili puoi avviare o mettere in pausa anche con il doppio tocco, e con Comandi puoi assegnarlo al tasto Azione di Apple Watch Ultra. Aggiungi la complicazione al quadrante per vedere il tempo rimanente alzando il polso. L’orologio raggiunge il Mac tramite questo telecomando su iPhone, quindi tieni aperto il telecomando sull’iPhone per controllare il timer. Se l’iPhone si blocca, l’orologio continua da solo a contare e a vibrare.

COME SI COLLEGA
Le due app si trovano sulla rete locale e comunicano direttamente. Nessun account da creare, nessun server in mezzo, e nulla passa da internet.

Il codice si inserisce una sola volta. Apri l’app, scegli il tuo Mac dall’elenco e digita il codice di abbinamento di 4 cifre che trovi in icona del timer → Telecomando, nella barra dei menu del Mac. Da quel momento si collega da sola ogni volta che la apri. Anche se in sala ci sono più Mac con StickyPresenter, il telecomando parla solo con quello abbinato.

Se non trova il Mac, l’app mostra un elenco delle cause più comuni.

PRIVACY
Nessun account, nessuna analisi, nessun tracciamento, nessuna pubblicità. Si scambiano solo le informazioni del timer e i comandi che tocchi, e solo con il Mac abbinato. Le tue note e i testi del gobbo non vengono mai inviati all’iPhone.

REQUISITI
• iPhone con iOS 17 o versioni successive
• Un Mac sulla stessa rete Wi-Fi con StickyPresenter aperto
• Accesso alla rete locale consentito su entrambi i dispositivi

Abbonamenti
L’abbonamento StickyPresenterRemote Pro si rinnova automaticamente. Il pagamento viene addebitato sul tuo Account Apple e l’abbonamento si rinnova se non lo disdici almeno 24 ore prima della fine del periodo. Puoi gestirlo o disdirlo in qualsiasi momento in Impostazioni.
Condizioni d’uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Informativa sulla privacy: https://m1zz.github.io/StickyPresenter/it/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/it/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/it/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/it/remote.html

## 포르투갈어(브라질) (pt-BR)

### 이름

StickyPresenter

### 부제

Notas, timer e teleprompter

### 키워드

controle,remoto,apresentação,contagem,regressiva,cronômetro,pomodoro,palestra,discurso,aula,ensaio

### 프로모션 텍스트

O Mac ficou do outro lado da sala? Inicie, pause, adicione 30 segundos ou tire o timer de cima de um slide direto do iPhone, pelo seu próprio Wi-Fi.

### 설명

StickyPresenterRemote é o controle remoto para iPhone do StickyPresenter para Mac. Durante a apresentação, o Mac quase sempre fica longe; com este app, os comandos do timer ficam na sua mão.

Ele não funciona sozinho. É preciso ter o StickyPresenter aberto em um Mac conectado à mesma rede Wi-Fi.

O QUE VOCÊ PODE FAZER
• Acompanhar a contagem regressiva: tempo restante, progresso e a fase do Pomodoro com o número do ciclo, atualizados a cada segundo
• Iniciar, pausar e redefinir
• Adicionar ou tirar 30 segundos quando uma parte se estende
• Iniciar um novo timer com as opções de 3, 5, 10 e 15 minutos
• Mudar o tamanho do widget para S, M ou L, para ficar legível até do fundo da sala
• Mover o widget arrastando-o em uma miniatura da disposição das telas do Mac. Se ele cobrir um slide, tire-o do caminho sem encostar no Mac. Com uma segunda tela, arraste-o para a outra.
• Ocultar o widget do público, trazer de volta para perto do painel um widget perdido ou apagar o timer

APPLE WATCH
Durante a apresentação, não dá para ficar olhando para uma tela. O Apple Watch mostra o tempo restante em letras grandes e toca no seu pulso quando faltam 5 minutos, quando falta 1 e no fim. Inicie ou pause com o botão de reproduzir e gire a Digital Crown um clique para adicionar ou tirar 30 segundos. Nos modelos compatíveis, o toque duplo também inicia ou pausa, e com o app Atalhos você pode colocar isso no botão de Ação do Apple Watch Ultra. Adicione a complicação ao mostrador para ver o tempo restante só de levantar o pulso. O relógio chega ao Mac por meio deste controle no iPhone, então deixe o controle aberto no iPhone para comandar o timer. Se o iPhone bloquear, o relógio continua contando e vibrando sozinho.

COMO SE CONECTA
Os dois apps se encontram na sua rede local e conversam diretamente. Não é preciso criar conta, não há servidor no meio e nada sai para a internet.

O código é digitado só uma vez. Abra o app, escolha seu Mac na lista e digite o código de pareamento de 4 dígitos que aparece em ícone do timer → Controle remoto, na barra de menus do Mac. Depois disso, a conexão é automática sempre que você abre o app. Mesmo com vários Macs rodando o StickyPresenter na sala, o controle só se conecta ao que foi pareado.

Se não encontrar seu Mac, o app mostra uma lista com as causas mais comuns.

PRIVACIDADE
Sem conta, sem análises, sem rastreamento e sem anúncios. Só são trocadas as informações do timer e os comandos que você toca, e apenas com o Mac pareado. Suas notas e os roteiros do teleprompter nunca são enviados ao iPhone.

REQUISITOS
• iPhone com iOS 17 ou posterior
• Um Mac na mesma rede Wi-Fi com o StickyPresenter aberto
• Acesso à rede local permitido nos dois dispositivos

Assinaturas
A assinatura StickyPresenterRemote Pro é renovada automaticamente. A cobrança é feita na sua Conta Apple, e a assinatura é renovada a menos que você cancele pelo menos 24 horas antes do fim do período. Gerencie ou cancele quando quiser em Ajustes.
Termos de Uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de Privacidade: https://m1zz.github.io/StickyPresenter/pt-BR/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/pt-BR/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/pt-BR/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/pt-BR/remote.html

## 러시아어 (ru)

### 이름

StickyPresenter

### 부제

Заметки и таймер для доклада

### 키워드

пульт,презентация,обратный,отсчет,секундомер,помодоро,доклад,выступление,лекция,семинар,спикер

### 프로모션 텍스트

Mac стоит в другом конце зала? Запускайте и ставьте на паузу, добавляйте 30 секунд или убирайте таймер со слайда прямо с iPhone по своей сети Wi-Fi.

### 설명

StickyPresenterRemote — пульт для iPhone к приложению StickyPresenter на Mac. Во время выступления до Mac обычно не дотянуться, а с этим приложением управление таймером всегда у вас в руке.

Отдельно оно не работает. Нужен Mac в той же сети Wi-Fi с запущенным StickyPresenter.

ЧТО МОЖНО ДЕЛАТЬ
• Следить за обратным отсчетом: оставшееся время, прогресс, фаза Помодоро и номер цикла обновляются каждую секунду
• Запускать, ставить на паузу и сбрасывать
• Добавлять или убирать 30 секунд, если часть выступления затянулась
• Запускать новый таймер на 3, 5, 10 или 15 минут
• Менять размер виджета на S, M или L, чтобы его было видно даже с последнего ряда
• Перемещать виджет, перетаскивая его на уменьшенной схеме экранов Mac. Если он закрывает слайд, уберите его, не подходя к Mac. Есть второй дисплей — перетащите виджет на него.
• Скрывать виджет от зрителей, возвращать потерявшийся виджет к панели или удалять таймер

APPLE WATCH
Во время выступления некогда поглядывать на экран. Apple Watch крупно показывают оставшееся время и мягко касаются запястья, когда остается 5 минут, 1 минута и когда время вышло. Запуск и пауза — кнопкой воспроизведения, а каждый щелчок колесика Digital Crown добавляет или убирает 30 секунд. На поддерживаемых моделях запускать и ставить на паузу можно и двойным касанием, а через Быстрые команды — назначить это на кнопку действия Apple Watch Ultra. Добавьте расширение на циферблат, и оставшееся время будет видно, стоит лишь поднять руку. Часы связываются с Mac через этот пульт на iPhone, поэтому для управления держите пульт открытым на iPhone. Если iPhone заблокируется, часы сами продолжат отсчет и вибрацию.

КАК ПРОИСХОДИТ ПОДКЛЮЧЕНИЕ
Оба приложения находят друг друга в локальной сети и общаются напрямую. Не нужно заводить аккаунт, нет промежуточного сервера, и ничего не уходит в интернет.

Код вводится только один раз. Откройте приложение, выберите свой Mac в списке и введите 4-значный код сопряжения, который показан в строке меню Mac в разделе «значок таймера → Пульт». Дальше приложение подключается само, как только вы его открываете. Даже если в зале несколько Mac с запущенным StickyPresenter, пульт подключается только к тому, с которым сопряжен.

Если Mac не находится, приложение покажет список частых причин.

КОНФИДЕНЦИАЛЬНОСТЬ
Без аккаунтов, аналитики, отслеживания и рекламы. Передаются только данные таймера и команды, которые вы нажимаете, и только между iPhone и сопряженным Mac. Заметки и тексты для телесуфлера никогда не отправляются на iPhone.

ТРЕБОВАНИЯ
• iPhone с iOS 17 или новее
• Mac в той же сети Wi-Fi с запущенным StickyPresenter
• Доступ к локальной сети разрешен на обоих устройствах

Подписки
StickyPresenterRemote Pro — подписка с автопродлением. Оплата списывается с вашего Аккаунта Apple, и подписка продлевается, если не отменить её минимум за 24 часа до конца периода. Управлять подпиской и отменить её можно в Настройках.
Условия использования (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Политика конфиденциальности: https://m1zz.github.io/StickyPresenter/ru/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/ru/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/ru/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/ru/remote.html

## 중국어 번체 (zh-Hant)

### 이름

StickyPresenter

### 부제

簡報便利貼與計時器

### 키워드

遙控器,倒數,番茄鐘,碼錶,演講,報告,講座,上課,會議,研討會,主持,時間管理,講師,培訓,提案,口試,投影片,無線,發表,彩排,番茄工作法,專注,教學,課堂,講課,時鐘,提醒,面試,學習,倒數器

### 프로모션 텍스트

Mac 離你再遠也沒關係。開始、暫停、加 30 秒，或把擋住投影片的計時器移開，在 iPhone 上點一下就好。

### 설명

StickyPresenterRemote 是 Mac 版 StickyPresenter 的 iPhone 遙控器。上台報告時 Mac 常常搆不到，它把計時器的操作交到你手上。

它無法單獨使用，需要在同一個 Wi-Fi 下有一台正在執行 StickyPresenter 的 Mac。

可以做什麼
• 查看倒數：每秒更新剩餘時間與進度，以及番茄鐘目前是專注還是休息、第幾輪
• 開始、暫停、重置
• 講得超時了，隨時加減 30 秒
• 用 3、5、10、15 分鐘預設開始新的計時器
• 把小工具大小切換成 S、M、L，坐在最後一排也看得清楚
• 在等比例縮小的 Mac 螢幕配置上拖移，移動小工具。擋到投影片時不必碰 Mac 就能移開；接了延伸顯示器，還能拖到另一個螢幕
• 對觀眾隱藏小工具、把找不到的小工具叫回面板旁邊，或刪除計時器

Apple Watch
簡報時沒空一直看螢幕。Apple Watch 會用大字顯示剩餘時間，並在剩 5 分鐘、剩 1 分鐘和時間到時輕點你的手腕。按播放按鈕開始或暫停，轉動數位錶冠一格就能加減 30 秒。在支援的機型上也能用點兩下手勢開始或暫停，透過捷徑還能把它設定到 Apple Watch Ultra 的動作按鈕。把複雜功能放上錶面，抬起手腕就看得到剩餘時間。手錶是透過這支 iPhone 遙控器連到 Mac，所以要操控時請在 iPhone 上保持遙控器開啟。就算 iPhone 鎖定，手錶也會自己繼續倒數並按時震動。

連線方式
兩個 App 會在區域網路中找到彼此並直接溝通。不必註冊帳號，中間沒有伺服器，也不會透過網際網路傳送任何資料。

配對碼只要輸入一次。打開 App，在列表中選擇你的 Mac，再輸入 Mac 選單列「計時器圖示 → 遙控」中顯示的 4 位數配對碼。之後只要打開 App，就會自動連上那台 Mac。即使同一個 Wi-Fi 下有好幾台 Mac 在執行 StickyPresenter，遙控器也只會連到和它配對的那一台。

找不到 Mac 時，App 會用檢查清單列出常見原因。

隱私權
沒有帳號、分析、追蹤或廣告。傳送的只有計時器資訊和你點按的指令，而且只在你與已配對的 Mac 之間傳送。便利貼和讀稿機講稿永遠不會傳到 iPhone。

系統需求
• 執行 iOS 17 或以上版本的 iPhone
• 在同一個 Wi-Fi 下執行 StickyPresenter 的 Mac
• 兩台裝置都允許取用本地網路

訂閱說明
StickyPresenterRemote Pro 為自動續訂訂閱。 費用會從你的 Apple 帳號扣款，除非在當期結束前至少 24 小時取消，否則將自動續訂。可隨時在「設定」中管理或取消。
使用條款（EULA）: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
隱私權政策: https://m1zz.github.io/StickyPresenter/zh-Hant/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/zh-Hant/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/zh-Hant/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/zh-Hant/remote.html

## 태국어 (th)

### 이름

StickyPresenter

### 부제

โน้ต จับเวลา เทเลพรอมป์เตอร์

### 키워드

รีโมท,รีโมต,นับถอยหลัง,ตัวจับเวลา,นาฬิกาจับเวลา,โพโมโดโร,นำเสนอ,บรรยาย,ประชุม,สัมมนา,สอน,พิธีกร,ซ้อม

### 프로모션 텍스트

Mac อยู่ไกลแค่ไหนก็ไม่เป็นไร เริ่ม หยุดชั่วคราว เพิ่ม 30 วินาที หรือย้ายตัวจับเวลาที่บังสไลด์ออกไปได้ทันทีจาก iPhone

### 설명

StickyPresenterRemote คือรีโมตบน iPhone สำหรับแอป StickyPresenter บน Mac ระหว่างพรีเซนต์ Mac มักอยู่ไกลมือ แอปนี้จึงนำการควบคุมตัวจับเวลามาไว้ในมือคุณ

แอปนี้ใช้งานเดี่ยวๆ ไม่ได้ ต้องมี Mac ที่เปิด StickyPresenter อยู่และเชื่อมต่อ Wi-Fi เดียวกัน

ทำอะไรได้บ้าง
• ดูเวลาที่เหลือ ความคืบหน้า และช่วงโฟกัสหรือพักของโพโมโดโรพร้อมรอบที่เท่าไร อัปเดตทุกวินาที
• เริ่ม หยุดชั่วคราว และรีเซ็ต
• เพิ่มหรือลด 30 วินาทีได้ทันทีเมื่อพูดเกินเวลา
• เริ่มตัวจับเวลาใหม่จากค่าที่ตั้งไว้ 3, 5, 10 และ 15 นาที
• ปรับขนาดวิดเจ็ตเป็น S, M หรือ L ให้คนแถวหลังก็อ่านได้
• ลากวิดเจ็ตบนภาพย่อของการจัดหน้าจอ Mac เพื่อย้ายตำแหน่ง ถ้าบังสไลด์ก็ย้ายออกได้โดยไม่ต้องแตะ Mac และถ้ามีจอเสริมก็ลากไปอีกจอได้
• ซ่อนวิดเจ็ตจากผู้ชม เรียกวิดเจ็ตที่หาไม่เจอกลับมาไว้ข้างแผงควบคุม หรือลบตัวจับเวลา

Apple Watch
ระหว่างนำเสนอไม่มีเวลามาคอยดูหน้าจอ Apple Watch จะแสดงเวลาที่เหลือตัวใหญ่ และแตะเตือนที่ข้อมือเมื่อเหลือ 5 นาที เหลือ 1 นาที และเมื่อหมดเวลา กดปุ่มเล่นเพื่อเริ่มหรือหยุดชั่วคราว และหมุน Digital Crown หนึ่งขั้นเพื่อเพิ่มหรือลด 30 วินาที รุ่นที่รองรับยังแตะสองครั้งเพื่อเริ่มหรือหยุดชั่วคราวได้ และใช้คำสั่งลัดตั้งให้ปุ่มแอ็คชั่นของ Apple Watch Ultra ได้ด้วย เพิ่มคอมพลิเคชั่นไว้บนหน้าปัด แค่ยกข้อมือก็เห็นเวลาที่เหลือ นาฬิกาเชื่อมกับ Mac ผ่านรีโมตบน iPhone นี้ จึงต้องเปิดรีโมตบน iPhone ค้างไว้เมื่อต้องการควบคุม ถ้า iPhone ล็อกไป นาฬิกาก็ยังนับถอยหลังและสั่นเตือนต่อเองได้

การเชื่อมต่อ
แอปทั้งสองค้นหากันเองในเครือข่ายภายในและสื่อสารกันโดยตรง ไม่ต้องสมัครบัญชี ไม่มีเซิร์ฟเวอร์คั่นกลาง และไม่มีการส่งข้อมูลออกไปทางอินเทอร์เน็ต

ใส่รหัสจับคู่แค่ครั้งแรกครั้งเดียว เปิดแอป เลือก Mac ของคุณจากรายการ แล้วพิมพ์รหัส 4 หลักที่แสดงใน ไอคอนตัวจับเวลา → รีโมต ในแถบเมนูของ Mac ครั้งต่อไปแค่เปิดแอปก็เชื่อมต่อกับ Mac เครื่องนั้นเอง แม้ใน Wi-Fi เดียวกันจะมี Mac ที่เปิด StickyPresenter อยู่หลายเครื่อง รีโมตก็จะเชื่อมต่อเฉพาะเครื่องที่จับคู่ไว้เท่านั้น

ถ้าหา Mac ไม่เจอ แอปจะแสดงรายการสาเหตุที่พบบ่อยให้ตรวจสอบ

ความเป็นส่วนตัว
ไม่มีบัญชี ไม่มีการวิเคราะห์ ไม่มีการติดตาม และไม่มีโฆษณา ข้อมูลที่รับส่งมีเพียงข้อมูลตัวจับเวลาและคำสั่งที่คุณแตะ และรับส่งกับ Mac ที่จับคู่ไว้เท่านั้น โน้ตและบทพูดในเทเลพร็อมป์เตอร์จะไม่ถูกส่งมายัง iPhone

สิ่งที่ต้องมี
• iPhone ที่ใช้ iOS 17 ขึ้นไป
• Mac ที่เปิด StickyPresenter อยู่ใน Wi-Fi เดียวกัน
• อนุญาตการเข้าถึงเครือข่ายภายในทั้งสองเครื่อง

การสมัครสมาชิก
StickyPresenterRemote Pro เป็นการสมัครสมาชิกที่ต่ออายุอัตโนมัติ ระบบจะเรียกเก็บเงินจากบัญชี Apple ของคุณและต่ออายุให้ เว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบ จัดการหรือยกเลิกได้ทุกเมื่อในการตั้งค่า
ข้อกำหนดการใช้งาน (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
นโยบายความเป็นส่วนตัว: https://m1zz.github.io/StickyPresenter/th/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/th/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/th/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/th/remote.html

## 베트남어 (vi)

### 이름

StickyPresenter

### 부제

Ghi chú, hẹn giờ thuyết trình

### 키워드

điều,khiển,từ,xa,đếm,ngược,bấm,pomodoro,diễn,giả,bài,giảng,hội,thảo,họp,lớp,học,phát,biểu,tập,dượt

### 프로모션 텍스트

Mac ở xa cũng không sao. Bắt đầu, tạm dừng, thêm 30 giây hay dời bộ hẹn giờ khỏi slide, tất cả ngay trên iPhone qua Wi-Fi của bạn.

### 설명

StickyPresenterRemote là ứng dụng điều khiển trên iPhone dành cho StickyPresenter trên Mac. Khi đang thuyết trình, bạn thường không với tới Mac; ứng dụng này đưa các nút điều khiển bộ hẹn giờ vào tay bạn.

Ứng dụng không dùng độc lập được. Bạn cần một máy Mac đang chạy StickyPresenter trong cùng mạng Wi-Fi.

BẠN CÓ THỂ LÀM GÌ
• Xem đếm ngược: thời gian còn lại, tiến độ, giai đoạn Pomodoro cùng số chu kỳ, cập nhật mỗi giây
• Bắt đầu, tạm dừng và đặt lại
• Thêm hoặc bớt 30 giây khi một phần nói bị dài
• Bắt đầu bộ hẹn giờ mới với các mốc có sẵn 3, 5, 10 và 15 phút
• Đổi kích thước widget sang S, M hoặc L để người ngồi cuối phòng vẫn đọc được
• Kéo widget trên hình thu nhỏ bố cục màn hình của Mac để di chuyển. Nếu widget che slide, bạn dời nó đi mà không cần chạm vào Mac. Có màn hình phụ thì kéo sang màn hình kia.
• Ẩn widget khỏi khán giả, gọi widget bị lạc về cạnh bảng điều khiển hoặc xóa bộ hẹn giờ

APPLE WATCH
Khi thuyết trình, bạn không có thời gian nhìn màn hình. Apple Watch hiển thị thời gian còn lại bằng chữ lớn và chạm nhẹ vào cổ tay khi còn 5 phút, còn 1 phút và khi hết giờ. Bắt đầu hoặc tạm dừng bằng nút phát, xoay Digital Crown một nấc để thêm hoặc bớt 30 giây. Trên các mẫu được hỗ trợ, bạn cũng có thể chạm hai lần để bắt đầu hoặc tạm dừng, và dùng Phím tắt để gán vào nút Tác vụ của Apple Watch Ultra. Thêm tổ hợp lên mặt đồng hồ để chỉ cần nâng cổ tay là thấy thời gian còn lại. Đồng hồ kết nối với Mac thông qua điều khiển trên iPhone này, vì vậy hãy để điều khiển mở trên iPhone khi muốn điều khiển. Nếu iPhone khóa màn hình, đồng hồ vẫn tự đếm ngược và rung báo.

CÁCH KẾT NỐI
Hai ứng dụng tự tìm thấy nhau trong mạng cục bộ và trao đổi trực tiếp. Không cần tạo tài khoản, không có máy chủ trung gian và không gửi gì ra Internet.

Bạn chỉ nhập mã một lần. Mở ứng dụng, chọn Mac của bạn trong danh sách, rồi nhập mã ghép nối 4 chữ số hiện ở biểu tượng bộ hẹn giờ → Điều khiển từ xa trên thanh menu của Mac. Từ đó trở đi, chỉ cần mở ứng dụng là tự kết nối với Mac đó. Dù trong phòng có nhiều Mac đang chạy StickyPresenter, ứng dụng chỉ kết nối với máy đã ghép nối.

Nếu không tìm thấy Mac, ứng dụng sẽ hiện danh sách những nguyên nhân thường gặp để bạn kiểm tra.

QUYỀN RIÊNG TƯ
Không tài khoản, không phân tích, không theo dõi, không quảng cáo. Chỉ thông tin bộ hẹn giờ và các lệnh bạn chạm được trao đổi, và chỉ với Mac đã ghép nối. Ghi chú và kịch bản máy nhắc chữ không bao giờ được gửi sang iPhone.

YÊU CẦU
• iPhone chạy iOS 17 trở lên
• Một máy Mac đang chạy StickyPresenter trong cùng mạng Wi-Fi
• Cho phép truy cập mạng cục bộ trên cả hai thiết bị

Gói đăng ký
StickyPresenterRemote Pro là gói đăng ký tự động gia hạn. Phí được tính vào Tài khoản Apple của bạn và gói sẽ tự gia hạn trừ khi bạn hủy ít nhất 24 giờ trước khi kỳ hạn kết thúc. Bạn có thể quản lý hoặc hủy bất cứ lúc nào trong Cài đặt.
Điều khoản sử dụng (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Chính sách quyền riêng tư: https://m1zz.github.io/StickyPresenter/vi/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/vi/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/vi/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/vi/remote.html

## 체코어 (cs)

### 이름

StickyPresenter

### 부제

Poznámky a časovač k řeči

### 키워드

dálkové,ovládání,ovladač,prezentace,odpočet,stopky,pomodoro,přednáška,projev,porada,seminář,řečník

### 프로모션 텍스트

Mac je na druhém konci sálu? Spusťte, pozastavte, přidejte 30 sekund nebo odsuňte časovač ze slidu přímo z iPhonu přes vlastní Wi-Fi.

### 설명

StickyPresenterRemote je dálkové ovládání pro iPhone k aplikaci StickyPresenter na Macu. Když prezentujete, Mac bývá z ruky. Tahle aplikace vám dá ovládání časovače přímo do dlaně.

Sama o sobě nefunguje. Potřebuje Mac ve stejné síti Wi-Fi, na kterém běží StickyPresenter.

CO UMÍ
• Ukazuje odpočet: zbývající čas, průběh a fázi Pomodora s číslem cyklu, aktualizované každou sekundu
• Spustit, pozastavit a obnovit
• Přidat nebo ubrat 30 sekund, když se některá část protáhne
• Spustit nový časovač z předvoleb 3, 5, 10 a 15 minut
• Přepnout velikost widgetu na S, M nebo L, aby byl čitelný i ze zadní řady
• Přesouvat widget tažením po zmenšeném rozložení obrazovek Macu. Když zakrývá slide, odsunete ho, aniž byste se Macu dotkli. S druhým displejem ho přetáhnete na vedlejší obrazovku.
• Skrýt widget před publikem, vrátit ztracený widget k panelu nebo smazat časovač

APPLE WATCH
Při prezentaci není čas koukat na displej. Apple Watch ukazují zbývající čas velkým písmem a klepnou vám na zápěstí, když zbývá 5 minut, 1 minuta a když čas vyprší. Spouštějte a pozastavujte tlačítkem přehrávání a každým cvaknutím korunky Digital Crown přidáte nebo uberete 30 sekund. Na podporovaných modelech funguje i dvojité klepnutí a přes Zkratky si to můžete přiřadit k Akčnímu tlačítku na Apple Watch Ultra. Přidejte komplikaci na ciferník a zbývající čas uvidíte, jen co zvednete zápěstí. Hodinky se k Macu dostanou přes tento ovladač v iPhonu, takže pro ovládání mějte ovladač v iPhonu otevřený. Když se iPhone zamkne, hodinky dál samy odpočítávají a vibrují.

JAK SE PŘIPOJUJE
Obě aplikace se najdou v místní síti a komunikují přímo. Žádný účet, žádný server uprostřed a nic nejde do internetu.

Kód zadáváte jen jednou. Otevřete aplikaci, vyberte svůj Mac ze seznamu a zadejte čtyřmístný spárovací kód z nabídky ikona časovače → Dálkové ovládání v řádku nabídek Macu. Pak se aplikace připojí sama, kdykoli ji otevřete. I když v sále běží StickyPresenter na více Macích, ovladač se připojí jen k tomu, se kterým je spárovaný.

Když Mac nenajde, aplikace ukáže seznam nejčastějších příčin.

SOUKROMÍ
Žádný účet, analytika, sledování ani reklamy. Vyměňují se jen údaje časovače a příkazy, na které klepnete, a jen se spárovaným Macem. Poznámky a texty pro čtecí zařízení se do iPhonu nikdy neposílají.

POŽADAVKY
• iPhone se systémem iOS 17 nebo novějším
• Mac ve stejné síti Wi-Fi se spuštěným StickyPresenterem
• Povolený přístup k místní síti na obou zařízeních

Předplatné
StickyPresenterRemote Pro je automaticky obnovované předplatné. Platba se strhává z vašeho Apple účtu a předplatné se obnoví, pokud ho nezrušíte alespoň 24 hodin před koncem období. Spravovat nebo zrušit ho můžete kdykoli v Nastavení.
Podmínky použití (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Zásady ochrany osobních údajů: https://m1zz.github.io/StickyPresenter/cs/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/cs/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/cs/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/cs/remote.html

## 덴마크어 (da)

### 이름

StickyPresenter

### 부제

Sedler og timer til oplægget

### 키워드

fjernbetjening,præsentation,nedtælling,stopur,pomodoro,tale,oplæg,møde,undervisning,forelæsning

### 프로모션 텍스트

Står din Mac i den anden ende af lokalet? Start, sæt på pause, læg 30 sekunder til eller flyt timeren væk fra et dias direkte fra iPhone over dit eget Wi-Fi.

### 설명

StickyPresenterRemote er iPhone-fjernbetjeningen til StickyPresenter på Mac. Når du præsenterer, er din Mac som regel uden for rækkevidde. Med denne app har du timerens knapper i hånden.

Appen virker ikke alene. Den kræver StickyPresenter på en Mac på det samme Wi-Fi-netværk.

DET KAN DU
• Følge nedtællingen: resterende tid, fremskridt og Pomodoro-fasen med cyklusnummer, opdateret hvert sekund
• Starte, sætte på pause og nulstille
• Lægge 30 sekunder til eller trække dem fra, når et afsnit trækker ud
• Starte en ny timer med forvalgene 3, 5, 10 og 15 minutter
• Skifte widgetstørrelsen til S, M eller L, så den kan læses helt nede bagerst
• Flytte widgetten ved at trække den på en miniature af din Macs skærmopsætning. Dækker den et dias, flytter du den uden at røre din Mac. Med en ekstra skærm trækker du den over på den anden.
• Skjule widgetten for publikum, hente en forsvundet widget tilbage ved siden af panelet eller slette timeren

APPLE WATCH
Når du præsenterer, er der ikke tid til at kigge på en skærm. Apple Watch viser den resterende tid med store tal og giver et tryk på håndleddet ved 5 minutter, ved 1 minut og når tiden er gået. Start eller sæt på pause med afspilningsknappen, og drej Digital Crown et hak for at lægge 30 sekunder til eller trække dem fra. På understøttede modeller kan du også bruge dobbelttryk, og med Genveje kan du lægge det på Handlingsknappen på Apple Watch Ultra. Føj komplikationen til urskiven, så ser du den resterende tid, bare du løfter håndleddet. Uret når din Mac via denne fjernbetjening på iPhone, så hold fjernbetjeningen åben på iPhone, når du vil styre timeren. Låses iPhone, fortsætter uret selv med at tælle ned og vibrere.

SÅDAN FORBINDER DEN
De to apps finder hinanden på dit lokale netværk og taler direkte sammen. Ingen konto, ingen server imellem, og intet sendes over internettet.

Du indtaster kun en kode én gang. Åbn appen, vælg din Mac på listen, og skriv den firecifrede parringskode, der står under timerikon → Fjernbetjening i Macens menulinje. Derefter forbinder den af sig selv, hver gang du åbner den. Selv hvis flere Mac-computere i lokalet kører StickyPresenter, taler fjernbetjeningen kun med den, den er parret med.

Kan den ikke finde din Mac, viser appen en tjekliste med de almindelige årsager.

ANONYMITET
Ingen konto, ingen analyse, ingen sporing, ingen reklamer. Kun timeroplysninger og de kommandoer, du trykker på, udveksles, og kun med din parrede Mac. Dine noter og teleprompter-manuskripter sendes aldrig til iPhone.

KRAV
• iPhone med iOS 17 eller nyere
• En Mac på samme Wi-Fi-netværk, der kører StickyPresenter
• Adgang til lokalt netværk tilladt på begge enheder

Abonnementer
StickyPresenterRemote Pro er et abonnement, der fornyes automatisk. Betalingen trækkes på din Apple-konto, og abonnementet fornyes, medmindre du opsiger det mindst 24 timer før perioden slutter. Administrer eller opsig når som helst i Indstillinger.
Brugsvilkår (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privatlivspolitik: https://m1zz.github.io/StickyPresenter/da/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/da/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/da/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/da/remote.html

## 그리스어 (el)

### 이름

StickyPresenter

### 부제

Σημειώσεις για την ομιλία

### 키워드

τηλεχειριστήριο,παρουσίαση,αντίστροφη,μέτρηση,pomodoro,ομιλία,διάλεξη,σεμινάριο,ομιλητής,μάθημα

### 프로모션 텍스트

Το Mac είναι στην άλλη άκρη της αίθουσας; Ξεκινήστε, κάντε παύση, προσθέστε 30 δευτερόλεπτα ή μετακινήστε το χρονόμετρο από μια διαφάνεια από το iPhone.

### 설명

Το StickyPresenterRemote είναι το τηλεχειριστήριο iPhone για το StickyPresenter στο Mac. Όταν παρουσιάζετε, το Mac συνήθως είναι μακριά σας. Με αυτή την εφαρμογή έχετε τον έλεγχο του χρονομέτρου στο χέρι.

Δεν λειτουργεί αυτόνομα. Χρειάζεται ένα Mac στο ίδιο δίκτυο Wi-Fi που εκτελεί το StickyPresenter.

ΤΙ ΜΠΟΡΕΙΤΕ ΝΑ ΚΑΝΕΤΕ
• Να βλέπετε την αντίστροφη μέτρηση: υπόλοιπο χρόνο, πρόοδο και τη φάση Pomodoro με τον αριθμό κύκλου, με ενημέρωση κάθε δευτερόλεπτο
• Έναρξη, παύση και επαναφορά
• Προσθήκη ή αφαίρεση 30 δευτερολέπτων όταν ένα μέρος τραβάει σε μάκρος
• Νέο χρονόμετρο από τις έτοιμες επιλογές 3, 5, 10 και 15 λεπτών
• Αλλαγή μεγέθους του widget σε S, M ή L, ώστε να διαβάζεται και από την τελευταία σειρά
• Μετακίνηση του widget σέρνοντάς το πάνω σε μια μικρογραφία της διάταξης οθονών του Mac. Αν κρύβει μια διαφάνεια, το απομακρύνετε χωρίς να αγγίξετε το Mac. Με δεύτερη οθόνη, το σέρνετε στην άλλη.
• Απόκρυψη του widget από το κοινό, επαναφορά ενός χαμένου widget δίπλα στο πάνελ ή διαγραφή του χρονομέτρου

APPLE WATCH
Την ώρα της παρουσίασης δεν προλαβαίνετε να κοιτάτε οθόνες. Το Apple Watch δείχνει τον υπόλοιπο χρόνο με μεγάλα ψηφία και σας ειδοποιεί με ένα άγγιγμα στον καρπό στα 5 λεπτά, στο 1 λεπτό και στο τέλος. Ξεκινήστε ή κάντε παύση με το κουμπί αναπαραγωγής και γυρίστε το Digital Crown κατά ένα βήμα για να προσθέσετε ή να αφαιρέσετε 30 δευτερόλεπτα. Στα συμβατά μοντέλα λειτουργεί και το διπλό πάτημα, ενώ μέσω των Συντομεύσεων μπορείτε να το βάλετε στο κουμπί Ενέργειας του Apple Watch Ultra. Προσθέστε την επιπλοκή στην πρόσοψη και θα βλέπετε τον υπόλοιπο χρόνο μόλις σηκώσετε τον καρπό. Το ρολόι φτάνει στο Mac μέσω αυτού του τηλεχειριστηρίου στο iPhone, οπότε κρατήστε το τηλεχειριστήριο ανοιχτό στο iPhone για να ελέγχετε το χρονόμετρο. Αν κλειδώσει το iPhone, το ρολόι συνεχίζει μόνο του την αντίστροφη μέτρηση και τις δονήσεις.

ΠΩΣ ΣΥΝΔΕΕΤΑΙ
Οι δύο εφαρμογές βρίσκουν η μία την άλλη στο τοπικό σας δίκτυο και επικοινωνούν απευθείας. Δεν χρειάζεται λογαριασμός, δεν υπάρχει διακομιστής στη μέση και τίποτα δεν στέλνεται στο διαδίκτυο.

Τον κωδικό τον εισάγετε μόνο μία φορά. Ανοίξτε την εφαρμογή, επιλέξτε το Mac σας από τη λίστα και πληκτρολογήστε τον τετραψήφιο κωδικό σύζευξης από το εικονίδιο χρονομέτρου → Τηλεχειριστήριο στη γραμμή μενού του Mac. Από εκεί και πέρα συνδέεται μόνη της κάθε φορά που την ανοίγετε. Ακόμη κι αν στην αίθουσα τρέχουν το StickyPresenter πολλά Mac, το τηλεχειριστήριο μιλά μόνο με εκείνο με το οποίο έχει συζευχθεί.

Αν δεν βρίσκει το Mac σας, η εφαρμογή δείχνει μια λίστα με τις συνηθισμένες αιτίες.

ΑΠΟΡΡΗΤΟ
Χωρίς λογαριασμό, αναλύσεις, παρακολούθηση ή διαφημίσεις. Ανταλλάσσονται μόνο οι πληροφορίες του χρονομέτρου και οι εντολές που πατάτε, και μόνο με το συζευγμένο Mac. Οι σημειώσεις και τα κείμενα του τελεπρόμπτερ δεν στέλνονται ποτέ στο iPhone.

ΑΠΑΙΤΗΣΕΙΣ
• iPhone με iOS 17 ή νεότερο
• Ένα Mac στο ίδιο δίκτυο Wi-Fi που εκτελεί το StickyPresenter
• Επιτρεπόμενη πρόσβαση στο τοπικό δίκτυο και στις δύο συσκευές

Συνδρομές
Το StickyPresenterRemote Pro είναι συνδρομή με αυτόματη ανανέωση. Η χρέωση γίνεται στον λογαριασμό Apple σας και η συνδρομή ανανεώνεται, εκτός αν την ακυρώσετε τουλάχιστον 24 ώρες πριν λήξει η περίοδος. Διαχειριστείτε ή ακυρώστε τη συνδρομή οποτεδήποτε από τις Ρυθμίσεις.
Όροι χρήσης (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Πολιτική απορρήτου: https://m1zz.github.io/StickyPresenter/el/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/el/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/el/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/el/remote.html

## 핀란드어 (fi)

### 이름

StickyPresenter

### 부제

Laput ja ajastin esitykseen

### 키워드

kaukosäädin,esitys,lähtölaskenta,sekuntikello,pomodoro,luento,kokous,seminaari,opetus,puhuja

### 프로모션 텍스트

Mac on salin toisella puolella? Käynnistä, keskeytä, lisää 30 sekuntia tai siirrä ajastin dian päältä suoraan iPhonesta omassa Wi-Fi-verkossasi.

### 설명

StickyPresenterRemote on iPhonen kauko-ohjain Macin StickyPresenter-apille. Kun pidät esitystä, Mac on yleensä ulottumattomissa. Tällä apilla ajastimen ohjaimet ovat kädessäsi.

Appi ei toimi yksinään. Se tarvitsee samassa Wi-Fi-verkossa olevan Macin, jossa StickyPresenter on käynnissä.

MITÄ VOIT TEHDÄ
• Seuraa lähtölaskentaa: jäljellä oleva aika, edistyminen sekä Pomodoron vaihe ja kierroksen numero päivittyvät joka sekunti
• Aloita, keskeytä ja nollaa
• Lisää tai vähennä 30 sekuntia, kun jokin osuus venyy
• Aloita uusi ajastin valmiista 3, 5, 10 ja 15 minuutin vaihtoehdoista
• Vaihda widgetin kooksi S, M tai L, jotta se näkyy takariviin asti
• Siirrä widgetiä vetämällä sitä Macin näyttöjärjestelyn pienoiskuvassa. Jos se peittää dian, siirrät sen pois koskematta Maciin. Toisen näytön kanssa vedät sen viereiselle näytölle.
• Piilota widget yleisöltä, tuo kadonnut widget takaisin paneelin viereen tai poista ajastin

APPLE WATCH
Esittäessä ei ehdi tuijottaa näyttöä. Apple Watch näyttää jäljellä olevan ajan isolla ja napauttaa rannetta, kun jäljellä on 5 minuuttia, 1 minuutti ja kun aika loppuu. Aloita tai keskeytä toistopainikkeella, ja käännä Digital Crownia pykälä lisätäksesi tai vähentääksesi 30 sekuntia. Tuetuissa malleissa myös kaksoisnapautus aloittaa tai keskeyttää, ja Pikakomennoilla voit liittää sen Apple Watch Ultran toimintopainikkeeseen. Lisää komplikaatio kellotauluun, niin näet jäljellä olevan ajan pelkällä ranteen nostolla. Kello yltää Maciin tämän iPhonen kaukosäätimen kautta, joten pidä kaukosäädin auki iPhonessa, kun haluat ohjata ajastinta. Jos iPhone lukittuu, kello jatkaa laskemista ja värinöitä itsekseen.

MITEN YHTEYS TOIMII
Apit löytävät toisensa paikallisverkosta ja viestivät suoraan keskenään. Ei tiliä, ei palvelinta välissä, eikä mitään lähetetä internetiin.

Koodi syötetään vain kerran. Avaa appi, valitse Macisi luettelosta ja kirjoita nelinumeroinen parituskoodi, joka näkyy Macin valikkorivillä kohdassa ajastinkuvake → Kauko-ohjain. Sen jälkeen appi yhdistää itse aina, kun avaat sen. Vaikka salissa olisi useita Maceja, joissa StickyPresenter on käynnissä, kauko-ohjain yhdistää vain siihen, jonka kanssa se on paritettu.

Jos Macia ei löydy, appi näyttää tarkistuslistan tavallisimmista syistä.

TIETOSUOJA
Ei tiliä, analytiikkaa, seurantaa eikä mainoksia. Vain ajastimen tiedot ja napauttamasi komennot vaihdetaan, ja vain paritetun Macin kanssa. Muistilappusi ja teleprompterin käsikirjoitukset eivät koskaan siirry iPhoneen.

VAATIMUKSET
• iPhone, jossa on iOS 17 tai uudempi
• Samassa Wi-Fi-verkossa oleva Mac, jossa StickyPresenter on käynnissä
• Paikallisen verkon käyttö sallittu molemmissa laitteissa

Tilaukset
StickyPresenterRemote Pro on automaattisesti uusiutuva tilaus. Maksu veloitetaan Apple-tililtäsi, ja tilaus uusiutuu, ellei sitä peruta vähintään 24 tuntia ennen jakson päättymistä. Hallitse tai peru tilaus milloin tahansa Asetuksissa.
Käyttöehdot (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Tietosuojakäytäntö: https://m1zz.github.io/StickyPresenter/fi/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/fi/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/fi/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/fi/remote.html

## 인도네시아어 (id)

### 이름

StickyPresenter

### 부제

Catatan & timer presentasi

### 키워드

kendali,jarak,jauh,hitung,mundur,stopwatch,pomodoro,pidato,ceramah,rapat,seminar,kuliah,pembicara,MC

### 프로모션 텍스트

Mac jauh di seberang ruangan? Mulai, jeda, tambah 30 detik, atau geser timer yang menutupi slide langsung dari iPhone lewat Wi-Fi Anda sendiri.

### 설명

StickyPresenterRemote adalah remote iPhone untuk StickyPresenter di Mac. Saat presentasi, Mac biasanya di luar jangkauan. Aplikasi ini menaruh kendali timer di genggaman Anda.

Aplikasi ini tidak bisa dipakai sendiri. Diperlukan Mac di jaringan Wi-Fi yang sama yang sedang menjalankan StickyPresenter.

YANG BISA ANDA LAKUKAN
• Pantau hitung mundur: sisa waktu, progres, serta fase Pomodoro beserta nomor siklusnya, diperbarui setiap detik
• Mulai, jeda, dan setel ulang
• Tambah atau kurangi 30 detik saat satu bagian berjalan terlalu lama
• Mulai timer baru dari pilihan 3, 5, 10, dan 15 menit
• Ubah ukuran widget ke S, M, atau L agar terbaca sampai barisan belakang
• Pindahkan widget dengan menyeretnya di miniatur susunan layar Mac. Jika menutupi slide, geser tanpa menyentuh Mac. Dengan layar kedua, seret ke layar sebelah.
• Sembunyikan widget dari penonton, panggil kembali widget yang hilang ke samping panel, atau hapus timer

APPLE WATCH
Saat presentasi, tak ada waktu untuk terus melihat layar. Apple Watch menampilkan sisa waktu dengan angka besar dan mengetuk pergelangan tangan saat sisa 5 menit, sisa 1 menit, dan saat waktu habis. Mulai atau jeda dengan tombol putar, dan putar Digital Crown satu klik untuk menambah atau mengurangi 30 detik. Di model yang didukung, ketuk dua kali juga bisa memulai atau menjeda, dan lewat Pintasan Anda bisa memasangnya di tombol Tindakan Apple Watch Ultra. Tambahkan komplikasi ke tampilan jam agar sisa waktu terlihat hanya dengan mengangkat pergelangan. Jam terhubung ke Mac melalui remote di iPhone ini, jadi biarkan remote tetap terbuka di iPhone untuk mengendalikan timer. Jika iPhone terkunci, jam tetap menghitung mundur dan bergetar sendiri.

CARA TERHUBUNG
Kedua aplikasi saling menemukan di jaringan lokal dan berkomunikasi langsung. Tidak perlu membuat akun, tidak ada server di tengah, dan tidak ada yang dikirim ke internet.

Kode cukup dimasukkan sekali. Buka aplikasi, pilih Mac Anda dari daftar, lalu ketik kode pemasangan 4 digit yang muncul di ikon timer → Remote pada bilah menu Mac. Setelah itu, aplikasi langsung terhubung setiap kali dibuka. Meskipun di ruangan ada beberapa Mac yang menjalankan StickyPresenter, remote hanya terhubung ke Mac yang sudah dipasangkan.

Jika Mac tidak ditemukan, aplikasi menampilkan daftar periksa penyebab yang umum.

PRIVASI
Tanpa akun, analitik, pelacakan, atau iklan. Yang dipertukarkan hanya informasi timer dan perintah yang Anda ketuk, dan hanya dengan Mac yang dipasangkan. Catatan tempel dan naskah teleprompter Anda tidak pernah dikirim ke iPhone.

PERSYARATAN
• iPhone dengan iOS 17 atau lebih baru
• Mac di jaringan Wi-Fi yang sama yang menjalankan StickyPresenter
• Akses Jaringan Lokal diizinkan di kedua perangkat

Langganan
StickyPresenterRemote Pro adalah langganan yang diperpanjang otomatis. Pembayaran ditagihkan ke Akun Apple Anda dan langganan diperpanjang kecuali dibatalkan paling lambat 24 jam sebelum periode berakhir. Kelola atau batalkan kapan saja di Pengaturan.
Ketentuan Penggunaan (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Kebijakan Privasi: https://m1zz.github.io/StickyPresenter/id/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/id/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/id/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/id/remote.html

## 노르웨이어(보크말) (nb)

### 이름

StickyPresenter

### 부제

Notater og tidtaker til talen

### 키워드

fjernkontroll,presentasjon,nedtelling,stoppeklokke,pomodoro,tale,møte,seminar,forelesning,taler

### 프로모션 텍스트

Står Macen i andre enden av rommet? Start, sett på pause, legg til 30 sekunder eller flytt tidtakeren bort fra et lysbilde rett fra iPhone over ditt eget Wi-Fi.

### 설명

StickyPresenterRemote er iPhone-fjernkontrollen til StickyPresenter på Mac. Når du presenterer, er Macen som regel utenfor rekkevidde. Med denne appen har du tidtakeren i hånden.

Appen fungerer ikke alene. Den trenger StickyPresenter på en Mac i samme Wi-Fi-nettverk.

DETTE KAN DU GJØRE
• Følge nedtellingen: gjenværende tid, fremdrift og Pomodoro-fasen med syklusnummer, oppdatert hvert sekund
• Starte, sette på pause og tilbakestille
• Legge til eller trekke fra 30 sekunder når en del drar ut
• Starte en ny tidtaker med forvalgene 3, 5, 10 og 15 minutter
• Endre widget-størrelsen til S, M eller L, så den kan leses helt bakerst i rommet
• Flytte widgeten ved å dra den på en miniatyr av skjermoppsettet på Macen. Dekker den et lysbilde, flytter du den uten å røre Macen. Med en ekstra skjerm drar du den over til den andre.
• Skjule widgeten for publikum, hente en borte widget tilbake ved siden av panelet eller slette tidtakeren

APPLE WATCH
Når du presenterer, har du ikke tid til å se på en skjerm. Apple Watch viser gjenstående tid med store tall og gir deg et trykk på håndleddet ved 5 minutter, ved 1 minutt og når tiden er ute. Start eller sett på pause med avspillingsknappen, og vri Digital Crown ett hakk for å legge til eller trekke fra 30 sekunder. På modeller som støtter det, kan du også bruke dobbelttrykk, og med Snarveier kan du legge det på Handlingsknappen på Apple Watch Ultra. Legg komplikasjonen på urskiven, så ser du gjenstående tid bare ved å løfte håndleddet. Klokken når Macen via denne fjernkontrollen på iPhone, så hold fjernkontrollen åpen på iPhone når du vil styre tidtakeren. Låses iPhone, fortsetter klokken selv å telle ned og vibrere.

SLIK KOBLER DEN TIL
De to appene finner hverandre på det lokale nettverket og snakker direkte sammen. Ingen konto, ingen server i midten, og ingenting sendes over internett.

Du skriver inn en kode bare én gang. Åpne appen, velg Macen din i listen, og skriv inn den firesifrede paringskoden som vises under tidtakerikon → Fjernkontroll i menylinjen på Macen. Deretter kobler den til av seg selv hver gang du åpner den. Selv om flere Mac-maskiner i rommet kjører StickyPresenter, snakker fjernkontrollen bare med den den er paret med.

Finner den ikke Macen, viser appen en sjekkliste med de vanligste årsakene.

PERSONVERN
Ingen konto, ingen analyse, ingen sporing, ingen reklame. Bare tidtakerinformasjon og kommandoene du trykker på, utveksles, og bare med den parede Macen. Notatene og teleprompter-manusene dine sendes aldri til iPhone.

KRAV
• iPhone med iOS 17 eller nyere
• En Mac i samme Wi-Fi-nettverk som kjører StickyPresenter
• Tilgang til lokalt nettverk tillatt på begge enhetene

Abonnementer
StickyPresenterRemote Pro er et abonnement som fornyes automatisk. Betalingen belastes Apple-kontoen din, og abonnementet fornyes med mindre du sier det opp minst 24 timer før perioden er over. Administrer eller si opp når som helst i Innstillinger.
Bruksvilkår (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Personvernerklæring: https://m1zz.github.io/StickyPresenter/nb/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/nb/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/nb/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/nb/remote.html

## 네덜란드어 (nl)

### 이름

StickyPresenter

### 부제

Notities en timer voor je talk

### 키워드

afstandsbediening,presentatie,aftellen,stopwatch,pomodoro,lezing,toespraak,vergadering,college,les

### 프로모션 텍스트

Staat je Mac aan de andere kant van de zaal? Start, pauzeer, tel er 30 seconden bij of schuif de timer van een dia af, gewoon vanaf je iPhone via je eigen wifi.

### 설명

StickyPresenterRemote is de iPhone-afstandsbediening voor StickyPresenter op de Mac. Tijdens een presentatie staat je Mac meestal buiten bereik. Met deze app heb je de timerknoppen in je hand.

De app werkt niet op zichzelf. Je hebt een Mac in hetzelfde wifinetwerk nodig waarop StickyPresenter draait.

WAT JE KUNT DOEN
• De countdown volgen: resterende tijd, voortgang en de Pomodorofase met cyclusnummer, elke seconde bijgewerkt
• Starten, pauzeren en terugzetten
• 30 seconden erbij of eraf als een onderdeel uitloopt
• Een nieuwe timer starten met de voorinstellingen 3, 5, 10 en 15 minuten
• De widgetgrootte op S, M of L zetten, zodat hij tot achter in de zaal leesbaar is
• De widget verplaatsen door hem te slepen op een miniatuur van de schermindeling van je Mac. Zit hij voor een dia, dan schuif je hem weg zonder je Mac aan te raken. Met een tweede scherm sleep je hem naar het andere scherm.
• De widget verbergen voor het publiek, een kwijtgeraakte widget terughalen naast het paneel of de timer verwijderen

APPLE WATCH
Tijdens een presentatie heb je geen tijd om naar een scherm te kijken. Apple Watch toont de resterende tijd in grote cijfers en tikt op je pols bij 5 minuten, bij 1 minuut en als de tijd om is. Start of pauzeer met de afspeelknop en draai de Digital Crown één klik om 30 seconden toe te voegen of eraf te halen. Op ondersteunde modellen kan dat ook met dubbeltikken, en via Opdrachten zet je het op de Actieknop van Apple Watch Ultra. Zet de complicatie op je wijzerplaat en je ziet de resterende tijd zodra je je pols optilt. Het horloge bereikt je Mac via deze afstandsbediening op je iPhone, dus houd de afstandsbediening open op je iPhone om de timer te bedienen. Vergrendelt je iPhone, dan blijft het horloge zelf aftellen en trillen.

ZO MAAKT HIJ VERBINDING
De twee apps vinden elkaar op je lokale netwerk en praten rechtstreeks met elkaar. Geen account, geen server ertussen en er gaat niets over het internet.

Je voert maar één keer een code in. Open de app, kies je Mac in de lijst en typ de koppelcode van 4 cijfers die in de menubalk van de Mac onder timersymbool → Afstandsbediening staat. Daarna maakt de app vanzelf verbinding zodra je hem opent. Ook als er in de zaal meerdere Macs met StickyPresenter draaien, praat de afstandsbediening alleen met de gekoppelde Mac.

Kan de app je Mac niet vinden, dan toont hij een checklist met de gebruikelijke oorzaken.

PRIVACY
Geen account, geen analyse, geen tracking, geen advertenties. Alleen timergegevens en de commando's die je tikt worden uitgewisseld, en alleen met je gekoppelde Mac. Je notities en teleprompterteksten worden nooit naar de iPhone gestuurd.

VEREISTEN
• iPhone met iOS 17 of nieuwer
• Een Mac in hetzelfde wifinetwerk waarop StickyPresenter draait
• Toegang tot lokaal netwerk toegestaan op beide apparaten

Abonnementen
StickyPresenterRemote Pro is een automatisch verlengend abonnement. De betaling loopt via je Apple Account en het abonnement wordt verlengd, tenzij je minstens 24 uur voor het einde van de periode opzegt. Beheer of zeg op wanneer je wilt in Instellingen.
Gebruiksvoorwaarden (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacybeleid: https://m1zz.github.io/StickyPresenter/nl/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/nl/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/nl/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/nl/remote.html

## 폴란드어 (pl)

### 이름

StickyPresenter

### 부제

Notatki i minutnik na scenę

### 키워드

pilot,prezentacja,odliczanie,stoper,pomodoro,wystąpienie,przemówienie,wykład,spotkanie,prelegent

### 프로모션 텍스트

Mac stoi na drugim końcu sali? Uruchom, wstrzymaj, dodaj 30 sekund albo odsuń minutnik ze slajdu prosto z iPhone’a, przez własną sieć Wi-Fi.

### 설명

StickyPresenterRemote to pilot na iPhone’a do aplikacji StickyPresenter na Maca. Podczas prezentacji Mac zwykle jest poza zasięgiem ręki. Ta aplikacja daje Ci sterowanie minutnikiem prosto do dłoni.

Nie działa samodzielnie. Potrzebny jest Mac w tej samej sieci Wi-Fi z uruchomioną aplikacją StickyPresenter.

CO MOŻESZ ZROBIĆ
• Śledzić odliczanie: pozostały czas, postęp oraz fazę Pomodoro z numerem cyklu, odświeżane co sekundę
• Uruchamiać, wstrzymywać i resetować
• Dodawać lub odejmować 30 sekund, gdy któraś część się przeciąga
• Uruchomić nowy minutnik z gotowych ustawień 3, 5, 10 i 15 minut
• Zmienić rozmiar widżetu na S, M lub L, by był czytelny nawet z ostatniego rzędu
• Przesuwać widżet, przeciągając go na miniaturze układu ekranów Maca. Jeśli zasłania slajd, odsuniesz go bez dotykania Maca. Przy drugim monitorze przeciągniesz go na sąsiedni ekran.
• Ukryć widżet przed publicznością, przywołać zagubiony widżet obok panelu lub usunąć minutnik

APPLE WATCH
Podczas prezentacji nie ma czasu zerkać na ekran. Apple Watch pokazuje pozostały czas dużymi cyframi i stuka w nadgarstek, gdy zostaje 5 minut, 1 minuta i gdy czas się kończy. Uruchamiaj i wstrzymuj przyciskiem odtwarzania, a każdy ząbek Digital Crown dodaje lub odejmuje 30 sekund. Na obsługiwanych modelach działa też podwójne stuknięcie, a przez Skróty możesz przypisać to do przycisku czynności w Apple Watch Ultra. Dodaj komplikację do tarczy, a pozostały czas zobaczysz, gdy tylko uniesiesz nadgarstek. Zegarek łączy się z Makiem przez tego pilota na iPhonie, więc aby sterować minutnikiem, trzymaj pilota otwartego na iPhonie. Gdy iPhone się zablokuje, zegarek sam dalej odlicza i wibruje.

JAK SIĘ ŁĄCZY
Obie aplikacje znajdują się nawzajem w sieci lokalnej i komunikują się bezpośrednio. Bez zakładania konta, bez serwera pośrodku i bez wysyłania czegokolwiek do internetu.

Kod wpisujesz tylko raz. Otwórz aplikację, wybierz swojego Maca z listy i wpisz 4-cyfrowy kod parowania z menu ikona minutnika → Pilot na pasku menu Maca. Od tej pory aplikacja łączy się sama przy każdym otwarciu. Nawet jeśli w sali działa StickyPresenter na kilku Macach, pilot łączy się tylko z tym, z którym jest sparowany.

Gdy nie może znaleźć Maca, aplikacja pokazuje listę najczęstszych przyczyn.

PRYWATNOŚĆ
Bez konta, analityki, śledzenia i reklam. Wymieniane są tylko dane minutnika i polecenia, które stukasz, i to wyłącznie ze sparowanym Makiem. Notatki i teksty do promptera nigdy nie trafiają na iPhone’a.

WYMAGANIA
• iPhone z systemem iOS 17 lub nowszym
• Mac w tej samej sieci Wi-Fi z uruchomioną aplikacją StickyPresenter
• Dostęp do sieci lokalnej dozwolony na obu urządzeniach

Subskrypcje
StickyPresenterRemote Pro to subskrypcja odnawiana automatycznie. Opłata jest pobierana z Twojego konta Apple, a subskrypcja odnawia się, jeśli nie anulujesz jej co najmniej 24 godziny przed końcem okresu. Zarządzaj subskrypcją lub anuluj ją w dowolnej chwili w Ustawieniach.
Warunki korzystania (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Polityka prywatności: https://m1zz.github.io/StickyPresenter/pl/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/pl/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/pl/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/pl/remote.html

## 스웨덴어 (sv)

### 이름

StickyPresenter

### 부제

Lappar och timer för talet

### 키워드

fjärrkontroll,presentation,nedräkning,stoppur,pomodoro,föredrag,möte,seminarium,föreläsning,lektion

### 프로모션 텍스트

Står din Mac i andra änden av rummet? Starta, pausa, lägg till 30 sekunder eller flytta timern från en bild direkt från iPhone via ditt eget wifi.

### 설명

StickyPresenterRemote är iPhone-fjärrkontrollen till StickyPresenter för Mac. När du presenterar är din Mac oftast utom räckhåll. Med den här appen har du timerns reglage i handen.

Appen fungerar inte på egen hand. Den behöver StickyPresenter på en Mac i samma wifi-nätverk.

DET HÄR KAN DU GÖRA
• Följa nedräkningen: återstående tid, förlopp och Pomodoro-fasen med cykelnummer, uppdaterat varje sekund
• Starta, pausa och återställa
• Lägga till eller dra bort 30 sekunder när ett avsnitt drar över
• Starta en ny timer med förinställningarna 3, 5, 10 och 15 minuter
• Ändra widgetstorleken till S, M eller L så att den syns ända längst bak
• Flytta widgeten genom att dra den på en miniatyr av din Macs skärmlayout. Täcker den en bild flyttar du undan den utan att röra din Mac. Med en extra skärm drar du över den till den andra.
• Dölja widgeten för publiken, hämta tillbaka en försvunnen widget bredvid panelen eller radera timern

APPLE WATCH
När du presenterar finns det ingen tid att titta på en skärm. Apple Watch visar återstående tid med stora siffror och knackar på handleden vid 5 minuter, vid 1 minut och när tiden är slut. Starta eller pausa med uppspelningsknappen och vrid Digital Crown ett snäpp för att lägga till eller dra bort 30 sekunder. På modeller som stöder det fungerar också dubbeltryck, och med Genvägar kan du lägga det på åtgärdsknappen på Apple Watch Ultra. Lägg till komplikationen på urtavlan så ser du återstående tid bara du lyfter handleden. Klockan når din Mac via den här fjärrkontrollen på iPhone, så håll fjärrkontrollen öppen på iPhone när du vill styra timern. Låses iPhone fortsätter klockan själv att räkna ner och vibrera.

SÅ ANSLUTER DEN
De två apparna hittar varandra i ditt lokala nätverk och pratar direkt med varandra. Inget konto, ingen server emellan och inget skickas över internet.

Du anger en kod bara en gång. Öppna appen, välj din Mac i listan och skriv in den fyrsiffriga ihopparningskoden som visas under timerikon → Fjärrkontroll i menyraden på din Mac. Därefter ansluter den av sig själv varje gång du öppnar den. Även om flera Mac-datorer i rummet kör StickyPresenter pratar fjärrkontrollen bara med den den är ihopparad med.

Hittar den inte din Mac visar appen en checklista med de vanligaste orsakerna.

INTEGRITET
Inget konto, ingen analys, ingen spårning, inga annonser. Bara timerinformation och de kommandon du trycker på utbyts, och bara med din ihopparade Mac. Dina anteckningar och teleprompter-manus skickas aldrig till iPhone.

KRAV
• iPhone med iOS 17 eller senare
• En Mac i samma wifi-nätverk som kör StickyPresenter
• Åtkomst till lokalt nätverk tillåten på båda enheterna

Prenumerationer
StickyPresenterRemote Pro är en prenumeration som förnyas automatiskt. Betalningen dras från ditt Apple-konto och prenumerationen förnyas om du inte avslutar den minst 24 timmar innan perioden slutar. Hantera eller avsluta när som helst i Inställningar.
Användarvillkor (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Integritetspolicy: https://m1zz.github.io/StickyPresenter/sv/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/sv/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/sv/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/sv/remote.html

## 튀르키예어 (tr)

### 이름

StickyPresenter

### 부제

Konuşma için not ve süre

### 키워드

kumanda,uzaktan,geri,sayım,kronometre,pomodoro,konuşma,konuşmacı,toplantı,seminer,ders,prova,eğitim

### 프로모션 텍스트

Mac salonun öbür ucunda mı? Başlatın, duraklatın, 30 saniye ekleyin ya da slaydı kapatan zamanlayıcıyı iPhone’dan kendi Wi-Fi’nizle kenara çekin.

### 설명

StickyPresenterRemote, Mac için StickyPresenter’ın iPhone uzaktan kumandasıdır. Sunum yaparken Mac’iniz genellikle elinizin altında olmaz. Bu uygulama zamanlayıcı kontrollerini avucunuza getirir.

Tek başına çalışmaz. Aynı Wi-Fi ağında StickyPresenter’ı çalıştıran bir Mac gerekir.

NELER YAPABİLİRSİNİZ
• Geri sayımı izleyin: kalan süre, ilerleme ve döngü numarasıyla birlikte Pomodoro aşaması her saniye güncellenir
• Başlatın, duraklatın ve sıfırlayın
• Bir bölüm uzadığında 30 saniye ekleyin ya da çıkarın
• 3, 5, 10 ve 15 dakikalık hazır sürelerle yeni bir zamanlayıcı başlatın
• Widget boyutunu S, M veya L yaparak en arka sıradan da okunmasını sağlayın
• Widget’ı, Mac’inizin ekran düzeninin küçük bir kopyası üzerinde sürükleyerek taşıyın. Bir slaydı kapatıyorsa Mac’e dokunmadan kenara çekin. İkinci bir ekran varsa diğer ekrana sürükleyin.
• Widget’ı izleyicilerden gizleyin, kaybolan bir widget’ı panelin yanına geri çağırın ya da zamanlayıcıyı silin

APPLE WATCH
Sunum sırasında ekrana bakacak vaktiniz olmaz. Apple Watch kalan süreyi büyük rakamlarla gösterir ve 5 dakika, 1 dakika kala ve süre dolunca bileğinize dokunarak haber verir. Oynat düğmesiyle başlatın ya da duraklatın, Digital Crown’u bir tık çevirerek 30 saniye ekleyin veya çıkarın. Desteklenen modellerde çift dokunmayla da başlatıp duraklatabilir, Kestirmeler ile bunu Apple Watch Ultra’nın Eylem düğmesine atayabilirsiniz. Komplikasyonu saat kadranına ekleyin, bileğinizi kaldırmanız kalan süreyi görmenize yeter. Saat, Mac’e bu iPhone kumandası üzerinden ulaşır; bu yüzden zamanlayıcıyı yönetmek için kumandayı iPhone’da açık tutun. iPhone kilitlense de saat geri saymayı ve titreşimi kendi başına sürdürür.

NASIL BAĞLANIR
İki uygulama yerel ağınızda birbirini bulur ve doğrudan iletişim kurar. Hesap açmanız gerekmez, arada sunucu yoktur ve internete hiçbir şey gönderilmez.

Kodu yalnızca bir kez girersiniz. Uygulamayı açın, listeden Mac’inizi seçin ve Mac’in menü çubuğundaki zamanlayıcı simgesi → Uzaktan Kumanda bölümünde görünen 4 haneli eşleştirme kodunu yazın. Bundan sonra uygulamayı her açtığınızda kendiliğinden bağlanır. Salonda StickyPresenter çalıştıran birden fazla Mac olsa bile kumanda yalnızca eşleştirildiği Mac’e bağlanır.

Mac’inizi bulamazsa uygulama, sık karşılaşılan nedenleri bir kontrol listesiyle gösterir.

GİZLİLİK
Hesap, analiz, izleme ve reklam yok. Yalnızca zamanlayıcı bilgileri ve dokunduğunuz komutlar paylaşılır, o da yalnızca eşleştirilmiş Mac’inizle. Notlarınız ve teleprompter metinleriniz asla iPhone’a gönderilmez.

GEREKSİNİMLER
• iOS 17 veya sonrası yüklü iPhone
• Aynı Wi-Fi ağında StickyPresenter’ı çalıştıran bir Mac
• Her iki cihazda da Yerel Ağ erişimine izin verilmiş olması

Abonelikler
StickyPresenterRemote Pro otomatik yenilenen bir aboneliktir. Ödeme Apple Hesabınızdan alınır ve dönem bitmeden en az 24 saat önce iptal edilmezse abonelik yenilenir. Ayarlar'dan istediğiniz zaman yönetebilir veya iptal edebilirsiniz.
Kullanım Koşulları (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://m1zz.github.io/StickyPresenter/tr/remote-privacy.html

### 지원 URL

https://m1zz.github.io/StickyPresenter/tr/remote.html

### 개인정보처리방침 URL

https://m1zz.github.io/StickyPresenter/tr/privacy.html

### 마케팅 URL

https://m1zz.github.io/StickyPresenter/tr/remote.html
