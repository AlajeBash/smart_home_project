import 'package:smart_home_front_end/exports.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: const MobileBody(),
      tabletBody: const TabletBody(),
      desktopBody: const DesktopBody(),
    );
  }
}
