import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Import theme
import 'core/theme/app_theme.dart';

// Import Blocs
import 'features/bluetooth_scanner/application/bluetooth_bloc.dart';
import 'features/wifi_scanner/application/wifi_scanner_bloc.dart';
import 'features/ir_scanner/application/ir_scanner_bloc.dart';
import 'features/magnetic_field/application/magnetic_scanner_bloc.dart';

// Import Splash Screen
import 'package:camera_detector/features/splash/application/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Bật log của FlutterBluePlus để debug
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng MultiBlocProvider để cung cấp tất cả BLoC
    return MultiBlocProvider(
      providers: [
        // Cung cấp BLoC Bluetooth
        BlocProvider<BluetoothScannerBloc>(
          create: (context) => BluetoothScannerBloc(),
        ),

        // Cung cấp BLoC Wifi
        BlocProvider<WifiScannerBloc>(create: (context) => WifiScannerBloc()),

        BlocProvider<IrScannerBloc>(create: (context) => IrScannerBloc()),
        BlocProvider<MagneticScannerBloc>(
          create: (context) => MagneticScannerBloc(),
        ),
      ],
      // MaterialApp bây giờ là con (child)
      child: MaterialApp(
        title: 'Camera Detector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
