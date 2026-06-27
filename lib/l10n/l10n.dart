/// TalkTranslate 多语言支持
///
/// 使用方式:
///   Text(L10n.of(context)!.login)
///   Text(L10n.of(context)!.welcome)
///
/// 支持语言: 中文 / English / 日本語 / 한국어 / Español
///           Français / Deutsch / Português / Русский
///           العربية / ภาษาไทย / Tiếng Việt
library;

import 'package:flutter/material.dart';

//  主入口 — 通过 L10n.of(context) 获取当前语言的翻译

class L10n {
  final Locale locale;
  final Map<String, String> _strings;

  L10n(this.locale, this._strings);

  /// 从 BuildContext 获取当前语言翻译
  static L10n? of(BuildContext context) =>
      Localizations.of<L10n>(context, L10n);

  /// 按 key 取翻译，找不到返回 key 本身
  String t(String key, [List<String>? args]) {
    var text = _strings[key] ?? key;
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }
    return text;
  }


  String get welcome => t('welcome');
  String get welcomeDesc => t('welcomeDesc');
  String get multiLang => t('multiLang');
  String get multiLangDesc => t('multiLangDesc');
  String get secure => t('secure');
  String get secureDesc => t('secureDesc');
  String get next => t('next');
  String get start => t('start');
  String get skip => t('skip');
  String get notConnected => t('notConnected');
  String get ready => t('ready');
  String get serverConfig => t('serverConfig');
  String get serverHint => t('serverHint');
  String get default_ => t('default');
  String get enterPhone => t('enterPhone');
  String get getCode => t('getCode');
  String get verificationCode => t('verificationCode');
  String get codeHint => t('codeHint');
  String get resend => t('resend');
  String get resendCountdown => t('resendCountdown');
  String get login => t('login');
  String get agreePrefix => t('agreePrefix');
  String get userAgreement => t('userAgreement');
  String get privacyPolicy => t('privacyPolicy');
  String get newUser => t('newUser');
  String get forgotPassword => t('forgotPassword');
  String get version => t('version');
  String get selectCountry => t('selectCountry');
  String get appName => t('appName');
  String get appDesc => t('appDesc');
  String get selectLangTitle => t('selectLangTitle');

  // 联系人页
  String get noContacts => t('noContacts');
  String get noContactsDesc => t('noContactsDesc');
  String get newCall => t('newCall');
  String get enterPeerPhone => t('enterPeerPhone');
  String get cancel => t('cancel');
  String get call => t('call');
  String get online => t('online');

  // 通话页
  String get calling => t('calling');
  String get ringing => t('ringing');

  // 注册页
  String get register => t('register');
  String get username => t('username');
  String get phone => t('phone');
  String get password => t('password');
  String get confirmPassword => t('confirmPassword');
  String get registerSuccess => t('registerSuccess');
  String get registerFail => t('registerFail');
  String get usernameHint => t('usernameHint');
  String get phoneHint => t('phoneHint');
  String get pwdMinLength => t('pwdMinLength');
  String get pwdNotMatch => t('pwdNotMatch');

  // 设置页
  String get settings => t('settings');
  String get translationEngine => t('translationEngine');
  String get apiKey => t('apiKey');
  String get engineConfig => t('engineConfig');
  String get testConnection => t('testConnection');
  String get testing => t('testing');
  String get connectionOk => t('connectionOk');
  String get connectionFail => t('connectionFail');
  String get save => t('save');
  String get saved => t('saved');
  String get apiKeyHint => t('apiKeyHint');
  String get secureStorage => t('secureStorage');
  String get selectEngine => t('selectEngine');
  String get noConfigNeeded => t('noConfigNeeded');
  String get language => t('language');
  String get myLang => t('myLang');
  String get peerLang => t('peerLang');
  String get searchLang => t('searchLang');
  String get selectLangPair => t('selectLangPair');

  // 通话设置
  String get callBehavior => t('callBehavior');
  String get autoAnswer => t('autoAnswer');
  String get subtitleInCall => t('subtitleInCall');
  String get noiseSuppression => t('noiseSuppression');
  String get noiseSuppressionDesc => t('noiseSuppressionDesc');
  String get speakerMode => t('扬声器模式_speakerMode');
  String get speakerModeDesc => t('扬声器模式Desc_speakerModeDesc');
  String get ttsEnabled => t('ttsEnabled');
  String get ttsEnabledDesc => t('ttsEnabledDesc');
  String get overlayPermission => t('overlayPermission');
  String get notificationPermission => t('notificationPermission');
  String get batteryOptimization => t('batteryOptimization');
  String get appKeeper => t('appKeeper');
  String get appKeeperDesc => t('appKeeperDesc');
  String get appKeeperHint => t('appKeeperHint');
  String get keepAliveOk => t('keepAliveOk');
  String get reconnecting => t('reconnecting');

  // 历史记录
  String get history => t('history');
  String get noHistory => t('noHistory');
  String get historyHint => t('historyHint');
  String get lastTranslation => t('lastTranslation');
  String get deleteAll => t('deleteAll');
  String get deleteConfirm => t('deleteConfirm');
  String get deleteDone => t('deleteDone');
  String get confirm => t('confirm');

  // 数据管理
  String get dataManagement => t('dataManagement');
  String get clearCache => t('clearCache');
  String get clearTranslationCache => t('clearTranslationCache');
  String get clearCallHistory => t('clearCallHistory');
  String get clearCacheConfirm => t('clearCacheConfirm');
  String get cacheCleared => t('cacheCleared');
  String get exportData => t('exportData');
  String get exportFeatureWip => t('exportFeatureWip');
  String get about => t('about');
  String get appVersion => t('appVersion');
  String get serverAddress => t('serverAddress');

  // 开发者选项
  String get devMode => t('devMode');
  String get serverDevOptions => t('serverDevOptions');

  // 通知 / Toast
  String get networkLost => t('networkLost');
  String get networkRestored => t('networkRestored');
  String get connecting => t('connecting');
  String get authFailed => t('authFailed');
  String get configServerFirst => t('configServerFirst');
  String get connected => t('connected');
  String get disconnected => t('disconnected');
  String get error => t('error');

  // 主题
  String get theme => t('theme');
  String get themeMode => t('themeMode');
  String get light => t('light');
  String get dark => t('dark');
  String get system => t('system');
  String get appearance => t('appearance');

  // 通话记录条目
  String minutesAgo(int n) => t('minutesAgo', [n.toString()]);
  String secondsAgo(int n) => t('secondsAgo', [n.toString()]);
  String todayAt(String time) => t('todayAt', [time]);
  String yesterdayAt(String time) => t('yesterdayAt', [time]);

  // 引擎名称
  String get engineSystem => t('engineSystem');
  String get engineDeepseek => t('engineDeepseek');
  String get engineOpenai => t('engineOpenai');
  String get engineClaude => t('engineClaude');
  String get engineDeepl => t('engineDeepl');
  String get engineBaidu => t('engineBaidu');

  // 忘记密码
  String get forgotPwdWip => t('forgotPwdWip');
}

//  LocalizationsDelegate

class L10nDelegate extends LocalizationsDelegate<L10n> {
  const L10nDelegate();

  @override
  bool isSupported(Locale locale) => supportedLocales.any((l) =>
      l.languageCode == locale.languageCode);

  @override
  Future<L10n> load(Locale locale) async {
    final strings = _allLanguages[locale.languageCode] ?? _allLanguages['zh']!;
    return L10n(locale, strings);
  }

  @override
  bool shouldReload(L10nDelegate old) => false;

  /// MaterialApp 支持的 locale 列表
  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
    Locale('ko', 'KR'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
    Locale('pt', 'BR'),
    Locale('ru', 'RU'),
    Locale('ar', 'SA'),
    Locale('th', 'TH'),
    Locale('vi', 'VN'),
  ];
}

//  翻译数据

final Map<String, Map<String, String>> _allLanguages = {
  'zh': _zh,
  'en': _en,
  'ja': _ja,
  'ko': _ko,
  'es': _es,
  'fr': _fr,
  'de': _de,
  'pt': _pt,
  'ru': _ru,
  'th': _th,
  'vi': _vi,
};

const _zh = {
  'welcome': '欢迎使用 TalkTranslate',
  'welcomeDesc': '实时翻译语音通话平台\n跨国通话 · AI 字幕 · 清晰音质',
  'multiLang': '支持多国语言',
  'multiLangDesc': '中、英、日、韩、西、法、德…\n自动识别、实时翻译',
  'secure': '安全可靠',
  'secureDesc': '端到端加密通话\n您的隐私安全无忧',
  'next': '下一步',
  'start': '开始使用',
  'skip': '跳过',
  'notConnected': '未连接',
  'ready': '就绪',
  'serverConfig': '服务器配置',
  'serverHint': 'wss://your-server.com:3459',
  'default': '默认',
  'enterPhone': '请输入手机号',
  'getCode': '获取验证码',
  'verificationCode': '验证码',
  'codeHint': '输入验证码',
  'resend': '重新获取',
  'resendCountdown': '重新获取 ({0}s)',
  'login': '登录',
  'agreePrefix': '我已阅读并同意 ',
  'userAgreement': '《用户协议》',
  'privacyPolicy': '《隐私政策》',
  'newUser': '新用户注册',
  'forgotPassword': '忘记密码',
  'version': 'Version 2.0.0',
  'selectCountry': '选择国家/地区',
  'appName': 'TalkTranslate',
  'appDesc': '实时翻译语音通话平台',
  'selectLangTitle': '选择语言 / Select Language',
  'noContacts': '暂无联系人',
  'noContactsDesc': '邀请好友或等待对方上线',
  'newCall': '新建通话',
  'enterPeerPhone': '输入对方手机号',
  'cancel': '取消',
  'call': '呼叫',
  'online': '在线',
  'calling': '正在呼叫...',
  'ringing': '响铃中...',
  'register': '注册',
  'username': '用户名',
  'phone': '手机号',
  'password': '密码',
  'confirmPassword': '确认密码',
  'registerSuccess': '注册成功，请登录',
  'registerFail': '注册失败',
  'usernameHint': '请输入用户名',
  'phoneHint': '手机号至少9位',
  'pwdMinLength': '密码至少6位',
  'pwdNotMatch': '两次密码不一致',
  'settings': '设置',
  'translationEngine': '翻译引擎',
  'apiKey': 'API Key',
  'engineConfig': '翻译引擎配置',
  'testConnection': '测试连接',
  'testing': '测试中...',
  'connectionOk': '✓ 连接成功',
  'connectionFail': '连接失败',
  'save': '保存',
  'saved': '✅ 设置已保存',
  'apiKeyHint': 'sk-... (从 platform.deepseek.com 获取)',
  'secureStorage': '使用 Flutter Secure Storage 硬件加密存储',
  'selectEngine': '选择翻译引擎',
  'noConfigNeeded': '无需配置',
  'language': '翻译语言',
  'myLang': '我的语言',
  'peerLang': '对方语言',
  'searchLang': '搜索语言...',
  'selectLangPair': '选择翻译的双向语言',
  'callBehavior': '通话行为设置',
  'autoAnswer': '收到来电时自动接听',
  'subtitleInCall': '通话中显示翻译字幕',
  'noiseSuppression': '降噪',
  'noiseSuppressionDesc': '过滤背景噪音，提升识别准确率',
  '扬声器模式_speakerMode': '扬声器模式',
  '扬声器模式Desc_speakerModeDesc': '默认使用扬声器外放',
  'ttsEnabled': 'TTS 语音合成',
  'ttsEnabledDesc': '将翻译结果朗读出来',
  'overlayPermission': '显示实时字幕',
  'notificationPermission': '通知权限 (Android 13+)',
  'batteryOptimization': '电池优化白名单',
  'appKeeper': '🛡️ 保活',
  'appKeeperDesc': '防止后台被系统杀死',
  'appKeeperHint': '国产 ROM 还需手动加入"受保护应用"',
  'keepAliveOk': '✅ 保活配置完成',
  'reconnecting': '网络不稳定，正在重连...',
  'history': '通话记录',
  'noHistory': '暂无通话记录',
  'historyHint': '完成一次通话后记录会自动保存',
  'lastTranslation': '最后翻译',
  'deleteAll': '删除所有历史通话记录',
  'deleteConfirm': '确定删除所有通话记录吗？此操作不可撤销。',
  'deleteDone': '✅ 通话记录已清除',
  'confirm': '确定',
  'dataManagement': '📊 数据管理',
  'clearCache': '清除本地翻译缓存数据',
  'clearTranslationCache': '清除翻译缓存',
  'clearCallHistory': '清除通话记录',
  'clearCacheConfirm': '确定清除翻译缓存吗？',
  'cacheCleared': '✅ 缓存已清除',
  'exportData': '导出数据',
  'exportFeatureWip': '📦 数据导出功能 (开发中)',
  'about': 'ℹ️ 关于',
  'appVersion': '版本',
  'serverAddress': '信令服务器地址',
  'serverDevOptions': '服务器与开发者选项',
  'devMode': '开发者模式',
  'networkLost': '网络已断开',
  'networkRestored': '网络已恢复 ({0})',
  'connecting': '正在连接...',
  'authFailed': '网络连接失败，请检查服务器地址和网络',
  'configServerFirst': '请先设置服务器地址（设置页或连续点击Logo 5次进入开发者模式）',
  'connected': '已连接',
  'disconnected': '已断开',
  'error': '连接失败: {0}',
  'theme': '主题与显示',
  'themeMode': '主题模式',
  'light': '浅色',
  'dark': '深色',
  'system': '跟随系统',
  'appearance': '🎨 外观',
  'minutesAgo': '{0}分钟前',
  'secondsAgo': '{0}秒前',
  'todayAt': '今天 {0}',
  'yesterdayAt': '昨天 {0}',
  'engineSystem': '系统内置',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': '百度翻译',
  'forgotPwdWip': '密码重置功能开发中',
};

const _en = {
  'welcome': 'Welcome to TalkTranslate',
  'welcomeDesc': 'Real-time translation calling platform\nCross-border calls · AI Subtitles · Clear Audio',
  'multiLang': 'Multi-language Support',
  'multiLangDesc': 'Chinese, English, Japanese, Korean, Spanish, French, German…\nAuto-detect & real-time translation',
  'secure': 'Secure & Reliable',
  'secureDesc': 'End-to-end encrypted calls\nYour privacy is guaranteed',
  'next': 'Next',
  'start': 'Get Started',
  'skip': 'Skip',
  'notConnected': 'Not Connected',
  'ready': 'Ready',
  'serverConfig': 'Server Config',
  'serverHint': 'wss://your-server.com:3459',
  'default': 'Default',
  'enterPhone': 'Enter phone number',
  'getCode': 'Get Code',
  'verificationCode': 'Verification Code',
  'codeHint': 'Enter verification code',
  'resend': 'Resend',
  'resendCountdown': 'Resend ({0}s)',
  'login': 'Login',
  'agreePrefix': 'I have read and agree to ',
  'userAgreement': 'User Agreement',
  'privacyPolicy': 'Privacy Policy',
  'newUser': 'New User',
  'forgotPassword': 'Forgot Password',
  'version': 'Version 2.0.0',
  'selectCountry': 'Select Country',
  'appName': 'TalkTranslate',
  'appDesc': 'Real-time translation calling platform',
  'selectLangTitle': 'Select Language',
  'noContacts': 'No Contacts',
  'noContactsDesc': 'Invite friends or wait for them to come online',
  'newCall': 'New Call',
  'enterPeerPhone': 'Enter peer phone number',
  'cancel': 'Cancel',
  'call': 'Call',
  'online': 'Online',
  'calling': 'Calling...',
  'ringing': 'Ringing...',
  'register': 'Register',
  'username': 'Username',
  'phone': 'Phone',
  'password': 'Password',
  'confirmPassword': 'Confirm Password',
  'registerSuccess': 'Registration successful, please login',
  'registerFail': 'Registration failed',
  'usernameHint': 'Please enter username',
  'phoneHint': 'Phone number must be at least 9 digits',
  'pwdMinLength': 'Password must be at least 6 characters',
  'pwdNotMatch': 'Passwords do not match',
  'settings': 'Settings',
  'translationEngine': 'Translation Engine',
  'apiKey': 'API Key',
  'engineConfig': 'AI Translation Config',
  'testConnection': 'Test Connection',
  'testing': 'Testing...',
  'connectionOk': '✓ Connected',
  'connectionFail': 'Connection failed',
  'save': 'Save',
  'saved': '✅ Settings saved',
  'apiKeyHint': 'sk-... (get from platform.deepseek.com)',
  'secureStorage': 'Stored with Flutter Secure Storage (hardware encrypted)',
  'selectEngine': 'Select Translation Engine',
  'noConfigNeeded': 'No configuration needed',
  'language': 'Language',
  'myLang': 'My Language',
  'peerLang': 'Peer Language',
  'searchLang': 'Search language...',
  'selectLangPair': 'Select bidirectional translation languages',
  'callBehavior': 'Call Behavior',
  'autoAnswer': 'Auto-answer incoming calls',
  'subtitleInCall': 'Show subtitles during calls',
  'noiseSuppression': 'Noise Suppression',
  'noiseSuppressionDesc': 'Filter background noise for better recognition',
  '扬声器模式_speakerMode': 'Speaker Mode',
  '扬声器模式Desc_speakerModeDesc': 'Default to speakerphone',
  'ttsEnabled': 'TTS (Text-to-Speech)',
  'ttsEnabledDesc': 'Read translated text aloud',
  'overlayPermission': 'Show real-time subtitles',
  'notificationPermission': 'Notification Permission (Android 13+)',
  'batteryOptimization': 'Battery Optimization Whitelist',
  'appKeeper': '🛡️ Keep Alive',
  'appKeeperDesc': 'Prevent background process from being killed',
  'appKeeperHint': 'Chinese ROMs may need manual "Protected Apps" config',
  'keepAliveOk': '✅ Keep-alive configured',
  'reconnecting': 'Unstable network, reconnecting...',
  'history': 'Call History',
  'noHistory': 'No call history',
  'historyHint': 'Records are saved automatically after each call',
  'lastTranslation': 'Last translation',
  'deleteAll': 'Delete all call history',
  'deleteConfirm': 'Delete all call history? This action cannot be undone.',
  'deleteDone': '✅ Call history cleared',
  'confirm': 'Confirm',
  'dataManagement': '📊 Data Management',
  'clearCache': 'Clear local translation cache',
  'clearTranslationCache': 'Clear translation cache',
  'clearCallHistory': 'Clear call history',
  'clearCacheConfirm': 'Clear translation cache?',
  'cacheCleared': '✅ Cache cleared',
  'exportData': 'Export Data',
  'exportFeatureWip': '📦 Data export (Coming soon)',
  'about': 'ℹ️ About',
  'appVersion': 'Version',
  'serverAddress': 'WebSocket Server Address',
  'serverDevOptions': 'Server & Developer Options',
  'devMode': 'Developer Mode',
  'networkLost': 'Network lost',
  'networkRestored': 'Network restored ({0})',
  'connecting': 'Connecting...',
  'authFailed': 'Connection failed. Please check server address and network.',
  'configServerFirst': 'Please set server address first (Settings or tap Logo 5 times)',
  'connected': 'Connected',
  'disconnected': 'Disconnected',
  'error': 'Connection failed: {0}',
  'theme': 'Theme & Display',
  'themeMode': 'Theme Mode',
  'light': 'Light',
  'dark': 'Dark',
  'system': 'System',
  'appearance': '🎨 Appearance',
  'minutesAgo': '{0} min ago',
  'secondsAgo': '{0}s ago',
  'todayAt': 'Today {0}',
  'yesterdayAt': 'Yesterday {0}',
  'engineSystem': 'System Built-in',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'forgotPwdWip': 'Password reset under development',
};

const _ja = {
  'welcome': 'TalkTranslateへようこそ',
  'welcomeDesc': 'リアルタイム翻訳通話プラットフォーム\n国際通話 · AI字幕 · クリアな音質',
  'multiLang': '多言語対応',
  'multiLangDesc': '中日韓英仏独…\n自動認識、リアルタイム翻訳',
  'secure': '安全・安心',
  'secureDesc': 'エンドツーエンド暗号化通話\nプライバシーを完全保護',
  'next': '次へ',
  'start': '始める',
  'skip': 'スキップ',
  'notConnected': '未接続',
  'ready': '準備完了',
  'serverConfig': 'サーバー設定',
  'serverHint': 'wss://your-server.com:3459',
  'default': 'デフォルト',
  'enterPhone': '電話番号を入力',
  'getCode': '認証コード取得',
  'verificationCode': '認証コード',
  'codeHint': '認証コードを入力',
  'resend': '再送信',
  'resendCountdown': '再送信 ({0}秒)',
  'login': 'ログイン',
  'agreePrefix': '同意します ',
  'userAgreement': '利用規約',
  'privacyPolicy': 'プライバシーポリシー',
  'newUser': '新規登録',
  'forgotPassword': 'パスワードをお忘れの方',
  'version': 'Version 2.0.0',
  'selectCountry': '国を選択',
  'appName': 'TalkTranslate',
  'appDesc': 'リアルタイム翻訳通話プラットフォーム',
  'selectLangTitle': '言語を選択',
  'noContacts': '連絡先がありません',
  'noContactsDesc': '友達を招待するか、オンラインになるのをお待ちください',
  'newCall': '新規通話',
  'enterPeerPhone': '相手の電話番号を入力',
  'cancel': 'キャンセル',
  'call': '発信',
  'online': 'オンライン',
  'calling': '発信中...',
  'ringing': '呼び出し中...',
  'register': '登録',
  'username': 'ユーザー名',
  'phone': '電話番号',
  'password': 'パスワード',
  'confirmPassword': 'パスワード確認',
  'registerSuccess': '登録成功、ログインしてください',
  'registerFail': '登録失敗',
  'usernameHint': 'ユーザー名を入力',
  'phoneHint': '電話番号は9桁以上必要',
  'pwdMinLength': 'パスワードは6文字以上必要',
  'pwdNotMatch': 'パスワードが一致しません',
  'settings': '設定',
  'translationEngine': '翻訳エンジン',
  'apiKey': 'APIキー',
  'engineConfig': 'AI翻訳設定',
  'testConnection': '接続テスト',
  'testing': 'テスト中...',
  'connectionOk': '✓ 接続成功',
  'connectionFail': '接続失敗',
  'save': '保存',
  'saved': '✅ 設定を保存しました',
  'apiKeyHint': 'sk-... (platform.deepseek.com から取得)',
  'secureStorage': 'Flutter Secure Storage でハードウェア暗号化保存',
  'selectEngine': '翻訳エンジンを選択',
  'noConfigNeeded': '設定不要',
  'language': '翻訳言語',
  'myLang': '自分の言語',
  'peerLang': '相手の言語',
  'searchLang': '言語を検索...',
  'selectLangPair': '翻訳の言語ペアを選択',
  'callBehavior': '通話動作設定',
  'autoAnswer': '自動応答',
  'subtitleInCall': '通話中に字幕を表示',
  'noiseSuppression': 'ノイズ抑制',
  'noiseSuppressionDesc': '背景ノイズを除去し認識精度を向上',
  '扬声器模式_speakerMode': 'スピーカーモード',
  '扬声器模式Desc_speakerModeDesc': 'デフォルトでスピーカーを使用',
  'ttsEnabled': 'TTS音声合成',
  'ttsEnabledDesc': '翻訳結果を音声で読み上げ',
  'overlayPermission': 'リアルタイム字幕を表示',
  'notificationPermission': '通知権限 (Android 13+)',
  'batteryOptimization': 'バッテリー最適化の除外',
  'appKeeper': '🛡️ 常駐',
  'appKeeperDesc': 'バックグラウンドでの停止を防止',
  'appKeeperHint': '中国製ROMは手動で「保護アプリ」に追加が必要',
  'keepAliveOk': '✅ 常駐設定完了',
  'reconnecting': 'ネットワーク不安定、再接続中...',
  'history': '通話履歴',
  'noHistory': '通話履歴がありません',
  'historyHint': '通話終了後に自動保存されます',
  'lastTranslation': '最終翻訳',
  'deleteAll': '全履歴を削除',
  'deleteConfirm': 'すべての通話履歴を削除しますか？この操作は取り消せません。',
  'deleteDone': '✅ 通話履歴を削除しました',
  'confirm': '確認',
  'dataManagement': '📊 データ管理',
  'clearCache': 'ローカル翻訳キャッシュを削除',
  'clearTranslationCache': '翻訳キャッシュを削除',
  'clearCallHistory': '通話履歴を削除',
  'clearCacheConfirm': '翻訳キャッシュを削除しますか？',
  'cacheCleared': '✅ キャッシュを削除しました',
  'exportData': 'データエクスポート',
  'exportFeatureWip': '📦 データエクスポート (準備中)',
  'about': 'ℹ️ このアプリについて',
  'appVersion': 'バージョン',
  'serverAddress': 'WebSocketサーバーアドレス',
  'serverDevOptions': 'サーバー & 開発者オプション',
  'devMode': '開発者モード',
  'networkLost': 'ネットワークが切断されました',
  'networkRestored': 'ネットワークが復旧しました ({0})',
  'connecting': '接続中...',
  'authFailed': '接続失敗。サーバーアドレスとネットワークを確認してください。',
  'configServerFirst': 'サーバーアドレスを設定してください（設定画面またはロゴを5回タップ）',
  'connected': '接続済み',
  'disconnected': '切断されました',
  'error': '接続失敗: {0}',
  'theme': 'テーマと表示',
  'themeMode': 'テーマモード',
  'light': 'ライト',
  'dark': 'ダーク',
  'system': 'システムに従う',
  'appearance': '🎨 外観',
  'minutesAgo': '{0}分前',
  'secondsAgo': '{0}秒前',
  'todayAt': '今日 {0}',
  'yesterdayAt': '昨日 {0}',
  'engineSystem': 'システム内蔵',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'forgotPwdWip': 'パスワードリセットは開発中です',
};

const _ko = {
  'welcome': 'TalkTranslate에 오신 것을 환영합니다',
  'welcomeDesc': '실시간 번역 통화 플랫폼\n국제 통화 · AI 자막 · 선명한 음질',
  'multiLang': '다국어 지원',
  'multiLangDesc': '중, 영, 일, 한, 서, 불, 독…\n자동 인식, 실시간 번역',
  'secure': '안전하고 신뢰할 수 있는',
  'secureDesc': '종단간 암호화 통화\n개인정보 완벽 보호',
  'next': '다음',
  'start': '시작하기',
  'skip': '건너뛰기',
  'notConnected': '연결 안 됨',
  'ready': '준비 완료',
  'serverConfig': '서버 설정',
  'serverHint': 'wss://your-server.com:3459',
  'default': '기본값',
  'enterPhone': '전화번호 입력',
  'getCode': '인증번호 받기',
  'verificationCode': '인증번호',
  'codeHint': '인증번호 입력',
  'resend': '재전송',
  'resendCountdown': '재전송 ({0}초)',
  'login': '로그인',
  'agreePrefix': '동의합니다 ',
  'userAgreement': '이용약관',
  'privacyPolicy': '개인정보처리방침',
  'newUser': '회원가입',
  'forgotPassword': '비밀번호 찾기',
  'version': 'Version 2.0.0',
  'selectCountry': '국가 선택',
  'appName': 'TalkTranslate',
  'appDesc': '실시간 번역 통화 플랫폼',
  'selectLangTitle': '언어 선택',
  'noContacts': '연락처 없음',
  'noContactsDesc': '친구를 초대하거나 온라인이 될 때까지 기다리세요',
  'newCall': '새 통화',
  'enterPeerPhone': '상대방 전화번호 입력',
  'cancel': '취소',
  'call': '통화',
  'online': '온라인',
  'calling': '통화 중...',
  'ringing': '벨이 울리는 중...',
  'register': '가입',
  'username': '사용자명',
  'phone': '전화번호',
  'password': '비밀번호',
  'confirmPassword': '비밀번호 확인',
  'registerSuccess': '가입 성공, 로그인해주세요',
  'registerFail': '가입 실패',
  'usernameHint': '사용자명 입력',
  'phoneHint': '전화번호는 9자리 이상 필요',
  'pwdMinLength': '비밀번호는 6자리 이상 필요',
  'pwdNotMatch': '비밀번호가 일치하지 않습니다',
  'settings': '설정',
  'translationEngine': '번역 엔진',
  'apiKey': 'API 키',
  'engineConfig': 'AI 번역 설정',
  'testConnection': '연결 테스트',
  'testing': '테스트 중...',
  'connectionOk': '✓ 연결 성공',
  'connectionFail': '연결 실패',
  'save': '저장',
  'saved': '✅ 설정 저장됨',
  'apiKeyHint': 'sk-... (platform.deepseek.com에서 획득)',
  'secureStorage': 'Flutter Secure Storage 하드웨어 암호화 저장',
  'selectEngine': '번역 엔진 선택',
  'noConfigNeeded': '설정 불필요',
  'language': '번역 언어',
  'myLang': '내 언어',
  'peerLang': '상대방 언어',
  'searchLang': '언어 검색...',
  'selectLangPair': '번역 언어 쌍 선택',
  'callBehavior': '통화 동작 설정',
  'autoAnswer': '자동 응답',
  'subtitleInCall': '통화 중 자막 표시',
  'noiseSuppression': '노이즈 제거',
  'noiseSuppressionDesc': '배경 소음 필터링으로 인식률 향상',
  '扬声器模式_speakerMode': '스피커 모드',
  '扬声器模式Desc_speakerModeDesc': '기본 스피커폰 사용',
  'ttsEnabled': 'TTS 음성 합성',
  'ttsEnabledDesc': '번역 결과를 음성으로 읽기',
  'appKeeper': '🛡️ 상주',
  'appKeeperDesc': '백그라운드 종료 방지',
  'reconnecting': '네트워크 불안정, 재연결 중...',
  'history': '통화 기록',
  'noHistory': '통화 기록 없음',
  'deleteAll': '모든 통화 기록 삭제',
  'confirm': '확인',
  'appearance': '🎨 외관',
  'minutesAgo': '{0}분 전',
  'secondsAgo': '{0}초 전',
  'todayAt': '오늘 {0}',
  'yesterdayAt': '어제 {0}',
  'engineSystem': '시스템 내장',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'forgotPwdWip': '비밀번호 재설정 기능 개발 중',
};

const _es = {
  'welcome': 'Bienvenido a TalkTranslate',
  'welcomeDesc': 'Plataforma de llamadas con traducción en tiempo real\nLlamadas internacionales · Subtítulos IA · Audio claro',
  'next': 'Siguiente',
  'start': 'Comenzar',
  'skip': 'Saltar',
  'login': 'Iniciar sesión',
  'register': 'Registrarse',
  'username': 'Nombre de usuario',
  'phone': 'Teléfono',
  'password': 'Contraseña',
  'confirmPassword': 'Confirmar contraseña',
  'settings': 'Ajustes',
  'save': 'Guardar',
  'cancel': 'Cancelar',
  'call': 'Llamar',
  'online': 'En línea',
  'calling': 'Llamando...',
  'ringing': 'Sonando...',
  'history': 'Historial',
  'confirm': 'Confirmar',
  'deleteAll': 'Eliminar todo el historial',
  'clearCache': 'Limpiar caché',
  'about': 'ℹ️ Acerca de',
  'appVersion': 'Versión',
  'minutesAgo': 'hace {0} min',
  'secondsAgo': 'hace {0}s',
  'todayAt': 'Hoy {0}',
  'yesterdayAt': 'Ayer {0}',
  'engineSystem': 'Sistema integrado',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'connecting': 'Conectando...',
  'connected': 'Conectado',
  'disconnected': 'Desconectado',
  'networkLost': 'Red perdida',
  'networkRestored': 'Red restaurada ({0})',
  'selectLangTitle': 'Seleccionar idioma',
  'appName': 'TalkTranslate',
};

const _fr = {
  'welcome': 'Bienvenue sur TalkTranslate',
  'welcomeDesc': 'Plateforme d\'appels avec traduction en temps réel\nAppels internationaux · Sous-titres IA · Audio clair',
  'next': 'Suivant',
  'start': 'Commencer',
  'skip': 'Passer',
  'login': 'Connexion',
  'register': 'S\'inscrire',
  'username': 'Nom d\'utilisateur',
  'phone': 'Téléphone',
  'password': 'Mot de passe',
  'confirmPassword': 'Confirmer le mot de passe',
  'settings': 'Paramètres',
  'save': 'Enregistrer',
  'cancel': 'Annuler',
  'call': 'Appeler',
  'online': 'En ligne',
  'calling': 'Appel en cours...',
  'ringing': 'Sonnerie...',
  'history': 'Historique',
  'confirm': 'Confirmer',
  'about': 'ℹ️ À propos',
  'appVersion': 'Version',
  'minutesAgo': 'il y a {0} min',
  'secondsAgo': 'il y a {0}s',
  'todayAt': 'Aujourd\'hui {0}',
  'yesterdayAt': 'Hier {0}',
  'engineSystem': 'Intégré au système',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'connecting': 'Connexion...',
  'connected': 'Connecté',
  'disconnected': 'Déconnecté',
  'selectLangTitle': 'Choisir la langue',
  'appName': 'TalkTranslate',
  'networkRestored': 'Réseau restauré ({0})',
};

const _de = {
  'welcome': 'Willkommen bei TalkTranslate',
  'welcomeDesc': 'Echtzeit-Übersetzungs-Anrufplattform\nInternationale Anrufe · KI-Untertitel · Klare Audioqualität',
  'next': 'Weiter',
  'start': 'Loslegen',
  'skip': 'Überspringen',
  'login': 'Anmelden',
  'register': 'Registrieren',
  'username': 'Benutzername',
  'phone': 'Telefon',
  'password': 'Passwort',
  'confirmPassword': 'Passwort bestätigen',
  'settings': 'Einstellungen',
  'save': 'Speichern',
  'cancel': 'Abbrechen',
  'call': 'Anrufen',
  'online': 'Online',
  'calling': 'Wird gewählt...',
  'ringing': 'Klingelt...',
  'history': 'Verlauf',
  'confirm': 'Bestätigen',
  'about': 'ℹ️ Über',
  'appVersion': 'Version',
  'minutesAgo': 'vor {0} Min.',
  'secondsAgo': 'vor {0}s',
  'todayAt': 'Heute {0}',
  'yesterdayAt': 'Gestern {0}',
  'engineSystem': 'Systemintegriert',
  'engineDeepseek': 'DeepSeek',
  'engineOpenai': 'OpenAI',
  'engineClaude': 'Claude',
  'engineDeepl': 'DeepL',
  'engineBaidu': 'Baidu',
  'selectLangTitle': 'Sprache auswählen',
  'appName': 'TalkTranslate',
  'connected': 'Verbunden',
};

const _pt = {
  'welcome': 'Bem-vindo ao TalkTranslate',
  'welcomeDesc': 'Plataforma de chamadas com tradução em tempo real\nChamadas internacionais · Legendas IA · Áudio claro',
  'next': 'Próximo',
  'start': 'Começar',
  'skip': 'Pular',
  'login': 'Entrar',
  'register': 'Cadastrar',
  'settings': 'Configurações',
  'save': 'Salvar',
  'cancel': 'Cancelar',
  'call': 'Ligar',
  'online': 'Online',
  'calling': 'Chamando...',
  'history': 'Histórico',
  'confirm': 'Confirmar',
  'about': 'ℹ️ Sobre',
  'appVersion': 'Versão',
  'minutesAgo': 'há {0} min',
  'secondsAgo': 'há {0}s',
  'todayAt': 'Hoje {0}',
  'yesterdayAt': 'Ontem {0}',
  'appName': 'TalkTranslate',
  'selectLangTitle': 'Selecionar idioma',
};

const _ru = {
  'welcome': 'Добро пожаловать в TalkTranslate',
  'welcomeDesc': 'Платформа для звонков с переводом в реальном времени\nМеждународные звонки · ИИ-субтитры · Чистый звук',
  'next': 'Далее',
  'start': 'Начать',
  'skip': 'Пропустить',
  'login': 'Войти',
  'register': 'Регистрация',
  'settings': 'Настройки',
  'save': 'Сохранить',
  'cancel': 'Отмена',
  'call': 'Звонить',
  'online': 'Онлайн',
  'calling': 'Звонок...',
  'history': 'История',
  'confirm': 'Подтвердить',
  'about': 'ℹ️ О программе',
  'appVersion': 'Версия',
  'minutesAgo': '{0} мин. назад',
  'secondsAgo': '{0} сек. назад',
  'todayAt': 'Сегодня {0}',
  'yesterdayAt': 'Вчера {0}',
  'appName': 'TalkTranslate',
  'selectLangTitle': 'Выбрать язык',
  'connected': 'Подключено',
};

const _th = {
  'welcome': 'ยินดีต้อนรับสู่ TalkTranslate',
  'welcomeDesc': 'แพลตฟอร์มโทรศัพท์พร้อมแปลภาษาฉับพลัน\nโทรต่างประเทศ · คำบรรยาย AI · เสียงคมชัด',
  'next': 'ถัดไป',
  'start': 'เริ่มต้น',
  'skip': 'ข้าม',
  'login': 'เข้าสู่ระบบ',
  'register': 'สมัครสมาชิก',
  'settings': 'การตั้งค่า',
  'save': 'บันทึก',
  'cancel': 'ยกเลิก',
  'call': 'โทร',
  'online': 'ออนไลน์',
  'calling': 'กำลังโทร...',
  'history': 'ประวัติ',
  'confirm': 'ยืนยัน',
  'about': 'ℹ️ เกี่ยวกับ',
  'appVersion': 'เวอร์ชัน',
  'appName': 'TalkTranslate',
  'selectLangTitle': 'เลือกภาษา',
  'connected': 'เชื่อมต่อแล้ว',
};

const _vi = {
  'welcome': 'Chào mừng đến với TalkTranslate',
  'welcomeDesc': 'Nền tảng gọi điện dịch thuật thời gian thực\nGọi quốc tế · Phụ đề AI · Âm thanh rõ ràng',
  'next': 'Tiếp theo',
  'start': 'Bắt đầu',
  'skip': 'Bỏ qua',
  'login': 'Đăng nhập',
  'register': 'Đăng ký',
  'settings': 'Cài đặt',
  'save': 'Lưu',
  'cancel': 'Hủy',
  'call': 'Gọi',
  'online': 'Trực tuyến',
  'calling': 'Đang gọi...',
  'history': 'Lịch sử',
  'confirm': 'Xác nhận',
  'about': 'ℹ️ Giới thiệu',
  'appVersion': 'Phiên bản',
  'appName': 'TalkTranslate',
  'selectLangTitle': 'Chọn ngôn ngữ',
  'connected': 'Đã kết nối',
};
