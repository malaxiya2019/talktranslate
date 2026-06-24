import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
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
        title: 'TalkTranslate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/app': (_) => const AppShell(),
        },
      ),
    );
  }
}
