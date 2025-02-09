import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devices = [];
  BluetoothConnection? connection;
  BluetoothDevice? connectedDevice;
  String gear = "N";
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      scanForDevices();
    });
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void scanForDevices() async {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();
    setState(() {
      devices = bondedDevices;
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    if (connection != null && connection!.isConnected) {
      print("Already connected to a device.");
      return;
    }

    try {
      BluetoothConnection.toAddress(device.address).then((_connection) {
        setState(() {
          connection = _connection;
          connectedDevice = device;
        });

        connection!.input!.listen((Uint8List data) {
          setState(() {
            gear = String.fromCharCodes(data).trim();
          });
        }, onDone: () {
          print("Disconnected");
          setState(() {
            connection = null;
            connectedDevice = null;
          });
        });
      }).catchError((error) {
        print("Connection failed: $error");
      });
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Bluetooth Gear Indicator")),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: isScanning ? null : scanForDevices,
              child: Text(isScanning ? "Scanning..." : "Scan Devices"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.name ?? "Unknown Device"),
                    subtitle: Text(device.address),
                    trailing: ElevatedButton(
                      onPressed: () => connectToDevice(device),
                      child: const Text("Connect"),
                    ),
                  );
                },
              ),
            ),
            if (connectedDevice != null) ...[
              const Divider(),
              Text("Connected to: ${connectedDevice!.name}", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              Image.asset('images/${gear.trim()}.png', scale: 0.3),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
