import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/settings_screen.dart';
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
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        title: 'TalkTranslate v2',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        locale: provider.locale,
        supportedLocales: AppLanguage.supportedLocales,
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
      ),
    );
  }
}
