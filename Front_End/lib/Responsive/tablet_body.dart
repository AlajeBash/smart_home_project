import 'package:smart_home_front_end/exports.dart';

class TabletBody extends StatefulWidget {
  const TabletBody({super.key});

  @override
  State<TabletBody> createState() => _TabletBodyState();
}

class _TabletBodyState extends State<TabletBody> {
  final NetworkService _networkService = NetworkService();

  double? temperature;
  double? humidity;
  bool relayState = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _networkService.listenToSensorData().listen((data) {
      setState(() {
        temperature = data["temperature"];
        humidity = data["humidity"];
      });
    });

    _networkService.listenToRelayState().listen((state) {
      setState(() {
        relayState = state;
      });
    });
  }

  void _toggleRelayState(bool value) {
    _networkService.toggleRelayState(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home - Tablet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Living Room Card
              Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.home, color: Colors.green),
                  title: const Text(
                    "Living Room",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Temperature and Humidity Widgets in a Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ListTile(
                        leading:
                            const Icon(Icons.thermostat, color: Colors.red),
                        title: const Text(
                          "Temperature",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${temperature ?? '--'}°C",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ListTile(
                        leading:
                            const Icon(Icons.water_drop, color: Colors.blue),
                        title: const Text(
                          "Humidity",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${humidity ?? '--'}%",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Gauges in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Card(
                    elevation: 4,
                    child: TemperatureGauge(temperature: temperature ?? 0.0),
                  ),
                  const SizedBox(width: 20),
                  Card(
                    elevation: 4,
                    child: HumidityGauge(humidity: humidity ?? 0.0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Relay Switch
              Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(
                    Icons.lightbulb,
                    color: relayState ? Colors.green : Colors.grey,
                  ),
                  title: const Text(
                    "Light Relay",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Switch(
                    value: relayState,
                    onChanged: (value) {
                      _toggleRelayState(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
