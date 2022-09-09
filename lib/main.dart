import 'package:agconnect_auth/agconnect_auth.dart';
import 'package:agconnect_clouddb/agconnect_clouddb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huawei_map/map.dart';
import 'package:huawei_push/huawei_push.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'HMS Testing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _token = 'no token';
  String? _currentUserUid = 'no user';
  Set<Marker> markerSet = {};
  AGConnectCloudDBZone? _zone;


  @override
  void initState() {
    initMap();
    initTokenStream();
    _initDS();
    super.initState();
    getToken();
  }

  void _onTokenEvent(String event) {
    // Requested tokens can be obtained here
    setState(() {
      _token = event;
    });
    debugPrint("TokenEvent: $_token");
  }

  void _onTokenError(Object error) {
    PlatformException e = error as PlatformException;
    debugPrint("TokenErrorEvent: ${e.message}");
  }

  Future<void> initTokenStream() async {
    if (!mounted) return;
    debugPrint("in initTokenStream");
    Push.setAutoInitEnabled(true);
    Push.getTokenStream.listen(_onTokenEvent, onError: _onTokenError);
  }

  void getToken() {
    // Call this method to request for a token
    Push.getToken("");
  }

  void initMap() {
    HuaweiMapInitializer.setApiKey(apiKey: 'DAEDAEfcYmuI/Ky8cSisrZwluqxKcSN5gWe6b9EGDWNq4mWPF69fdPact8FtnkGZfInzm9jNXPkCuSQy7Z0mYktRMJXPJRTCQdsr/g==');
    HuaweiMapInitializer.initializeMap();
  }

  Future<void> _initCurrentUser() async {
    final AGCUser? currentUser = await AGCAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() => _currentUserUid = currentUser.uid);
    } else {
      final SignInResult signInResult =
      await AGCAuth.instance.signInAnonymously();
      if (signInResult.user != null) {
        setState(() => _currentUserUid = signInResult.user?.uid ?? '');
      } else {
        setState(() => _currentUserUid = '???');
      }
    }
  }

  void saveLocation(LatLng loc) {

    setState(() {});

  }

  void _initDS () async {
    try {
      await _initCurrentUser();
      await AGConnectCloudDB.getInstance().initialize();
      await AGConnectCloudDB.getInstance().createObjectType();
      await _openZone();
    } catch (e) {
      rethrow;
    }
    debugPrint('**********************************   Complete initDS');
  }

  Future<void> _openZone() async {
    _zone = await AGConnectCloudDB.getInstance().openCloudDBZone(
      zoneConfig: AGConnectCloudDBZoneConfig(
          zoneName: 'company'),
    );
  }

  void _showDialog(BuildContext context, String title, [dynamic content]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content == null
              ? null
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text('$content'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (markerSet.isEmpty) {
      Marker loc = Marker(markerId: MarkerId('My Place'), position: const LatLng(3.3162913056865966, 101.53680620127085),visible: true);
      markerSet.add(loc);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'HMS Push Notification & Map Test',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: HuaweiMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(3.320827, 101.537246),
//                  target: LatLng(41.012959, 28.997438),
                  zoom: 12,
                ),
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                trafficEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: true,
                markers: markerSet,
                onClick: (loc) => saveLocation(loc),
              ),
            ),
            Text(
              'Token is: $_token',
              style: const TextStyle(fontSize: 8, overflow: TextOverflow.fade),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
