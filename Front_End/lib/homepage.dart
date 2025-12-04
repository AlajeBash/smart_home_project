import 'package:smart_home_front_end/exports.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Add this to remove the debug banner
      home: ResponsiveLayout(
        mobileBody: const MobileBody(),
        tabletBody: const TabletBody(),
        desktopBody: const DesktopBody(),
      ),
    );
  }
}
