import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/routes/router.dart';
import 'package:pay_pos/services/pay/localstorage.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/wallet/wallet.dart';
import 'package:pay_pos/state/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await init();

  // await MainDB().init('main');
  await PreferencesService().init(await SharedPreferences.getInstance());

  WalletService();

  runApp(provideAppState(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const theme = CupertinoThemeData(
    primaryColor: Color(0xFF3431C4),
    brightness: Brightness.light,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: CupertinoColors.label,
        fontSize: 16,
      ),
    ),
    applyThemeToAll: true,
  );

  final localStorage = LocalStorageService();

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();
  final observers = <NavigatorObserver>[];

  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    onLoad();
  }

  void onLoad() async {
    final placeId = await localStorage.getPlaceId();

    setState(() {
      _router = createRouter(
        _rootNavigatorKey,
        _shellNavigatorKey,
        observers,
        placeId: placeId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const SizedBox();
    }

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router!,
      theme: theme,
      title: 'Brussels Pay',
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.0)),
        child: CupertinoPageScaffold(
          key: const Key('main'),
          backgroundColor: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              Expanded(
                child: child != null
                    ? CupertinoTheme(
                        data: theme,
                        child: child,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
