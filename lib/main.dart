import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/app_language_provider.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appProvider = AppProvider();
  await appProvider.init();
  runApp(TalkTranslateApp(provider: appProvider));
}

class TalkTranslateApp extends StatelessWidget {
  final AppProvider provider;
  const TalkTranslateApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
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
