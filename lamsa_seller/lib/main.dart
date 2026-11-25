import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/gate/seller_gate.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // مؤقت للتشخيص: يعرض نص الخطأ بدل المربع الرمادي
  ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFFFFF3CD),
          padding: const EdgeInsets.all(12),
          child: Text(
            'UI error: ${details.exceptionAsString()}',
            maxLines: 25,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black, decoration: TextDecoration.none),
          ),
        ),
      );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LamsaSellerApp());
}

class LamsaSellerApp extends StatelessWidget {
  const LamsaSellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لمسة للتجار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SellerGate(),
    );
  }
}