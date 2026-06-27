import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'services/signaling_service.dart';
import 'providers/call_provider.dart';
import 'providers/app_language_provider.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/app_shell.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 先加载设置
  final settings = SettingsProvider();
  await settings.load();

  // 创建信令和通话服务
  final signaling = SignalingService();
  final callProvider = CallProvider(signaling);

  // 创建全局协调器
  final appProvider = AppProvider(
    settings: settings,
    callProvider: callProvider,
  );
  await appProvider.init();

  runApp(TalkTranslateApp(
    provider: appProvider,
    settings: settings,
    callProvider: callProvider,
  ));
}

class TalkTranslateApp extends StatelessWidget {
  final AppProvider provider;
  final SettingsProvider settings;
  final CallProvider callProvider;

  const TalkTranslateApp({
    super.key,
    required this.provider,
    required this.settings,
    required this.callProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: callProvider),
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
      ],
      child: Consumer<AppLanguageProvider>(
        builder: (context, langProvider, child) {
          return MaterialApp(
            title: 'TalkTranslate v2',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
            locale: langProvider.currentLocale,
            supportedLocales: const [
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
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              L10nDelegate(),
            ],
            initialRoute: '/',
            routes: {
              '/': (_) => const HomeScreen(),
              '/app': (_) => const AppShell(),
              '/register': (_) => const RegisterScreen(),
            },
          );
        },
      ),
    );
  }
}
