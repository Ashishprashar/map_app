import 'dart:async';
import 'dart:typed_data';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:math' as Math;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

// import 'address_search.dart';
// import 'place_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
//     BehaviorSubject<ReceivedNotification>();

// final BehaviorSubject<String?> selectNotificationSubject =
//     BehaviorSubject<String?>();

const MethodChannel platform =
    MethodChannel('dexterx.dev/flutter_local_notifications_example');

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

String? selectedNotificationPayload;
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_tests',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            defaultRingtoneType: null,
            enableVibration: true,
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High),
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupkey: 'basic_tests', channelGroupName: 'Basic tests'),
      ],
      debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Map Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _locationSubscription;
  List<Marker> markersList = [];
  List<GeoPoint> positionsList = [];
  final loc.Location _locationTracker = loc.Location();
  Marker? marker;
  double rotation = 0.0;
  Circle? circle;
  GoogleMapController? _controller;
  final positionCollection = FirebaseFirestore.instance.collection("positions");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final assetsAudioPlayer = AssetsAudioPlayer();
  static CameraPosition initialLocation = const CameraPosition(
    target: LatLng(12.87, 77.54),
    zoom: 14.4746,
  );
  var imageDataBreaker;
  @override
  initState() {
    super.initState();

    Future.delayed(Duration.zero).then((value) async {
      await fetchMarkers();
      imageDataBreaker = await getSpeedBreakerMarker();
      var location = await _locationTracker.getLocation();
      setState(() {
        initialLocation = CameraPosition(
          target: LatLng(location.latitude!, location.longitude!),
          zoom: 14.4746,
        );
      });
      var loc = await _locationTracker.getLocation();
      setState(() {
        rotation = location.heading ?? 0;
      });
    });
  }

  fetchMarkers() async {
    Uint8List imageData = await getSpeedBreakerMarker();
    final result = await positionCollection.get();
    print(result.docs[0].data());
    List markers = result.docs[0].data()["marker_position"];
    List<Marker> _markers = [];
    List<GeoPoint> _position = [];
    int i = 0;
    for (var element in markers) {
      _position.add(element);

      i += 1;
    }

    setState(() {
      positionsList = _position;
      markersList = _markers;
    });
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> getSpeedBreakerMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/speed-breaker.png");
    return byteData.buffer.asUint8List();
  }

  arePointsNear(checkPoint, centerPoint, km) {
    var ky = 40000 / 360;
    var kx = Math.cos(Math.pi * centerPoint.latitude / 180.0) * ky;
    var dx =
        (((centerPoint.longitude ?? 0) - (checkPoint!.longitude ?? 0)).abs()) *
            kx;
    var dy =
        ((centerPoint.latitude ?? 0) - (checkPoint.latitude ?? 0)).abs().abs() *
            ky;
    return Math.sqrt(dx * dx + dy * dy) <= km;
  }

  Future<void> _showNotificationCustomSound() async {
    assetsAudioPlayer.open(
      Audio("assets/notification.mp3"),
    );
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Speed Breaker detected',
            body: ' 🚧 🚧 🚧 🚧 🚧 🚧'));
  }

  void updateMarkerAndCircle(
      loc.LocationData newLocalData, Uint8List imageData) {
    setState(() {
      rotation = newLocalData.heading ?? 0;
    });
    LatLng latlng =
        LatLng(newLocalData.latitude ?? 0, newLocalData.longitude ?? 0);
    setState(() {
      marker = Marker(
          markerId: const MarkerId("home"),
          onTap: () {},
          position: latlng,
          rotation: newLocalData.heading ?? 0,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      circle = Circle(
          circleId: const CircleId("car"),
          radius: newLocalData.accuracy ?? 0,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(70));
    });
  }

  addMarker() async {
    Uint8List imageData = await getSpeedBreakerMarker();
    var location = await _locationTracker.getLocation();
    await positionCollection.doc("positions").update({
      "marker_position": FieldValue.arrayUnion(
          [GeoPoint(location.latitude!, location.longitude!)]),
    });
    setState(() {
      positionsList.add(GeoPoint(location.latitude!, location.longitude!));
      markersList.add(Marker(
          markerId: MarkerId((markersList.length + 1).toString()),
          rotation: rotation,
          icon: BitmapDescriptor.fromBytes(imageData),
          infoWindow: InfoWindow(
              title: (markersList.length + 1).toString() + " PIT HOle"),
          position: LatLng(location.latitude!, location.longitude!)));
    });
    // updateMarkerAndCircle(location, imageData);
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller!.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  bearing: 192.8334901395799,
                  target: LatLng(
                      newLocalData.latitude ?? 0, newLocalData.longitude ?? 0),
                  tilt: 0,
                  zoom: 18.00)));
          setState(() {
            rotation = newLocalData.heading ?? 0;
          });
          updateMarkerAndCircle(newLocalData, imageData);
          for (var pos in positionsList) {
            if (arePointsNear(
                newLocalData, LatLng(pos.latitude, pos.longitude), .01)) {
              // log("on Location");
              _showNotificationCustomSound();
            }
          }
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: initialLocation,
              // polylines: Set<Polyline>.of(polylines.values),
              markers: Set.of((marker != null)
                  ? [
                      marker!,
                      for (var i = 0; i < positionsList.length; i++) ...[
                        Marker(
                            markerId: MarkerId(i.toString()),
                            position: LatLng(positionsList[i].latitude,
                                positionsList[i].longitude),
                            // rotation: rotation,

                            draggable: false,
                            zIndex: 2,
                            flat: false,
                            anchor: const Offset(0.5, 0.5),
                            icon: BitmapDescriptor.fromBytes(imageDataBreaker))
                      ]
                    ]
                  : markersList),
              circles: Set.of((circle != null) ? [circle!] : []),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
            Positioned(
                bottom: 30,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          await addMarker();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Add new Breaker'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        )),
                    ElevatedButton(
                        onPressed: () async {
                          getCurrentLocation();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Start'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ))
                    // InkWell(
                    //   onTap: () {
                    //     getCurrentLocation();
                    //   },
                    //   child: Container(
                    //       height: 50,
                    //       width: 100,
                    //       color: Colors.blue,
                    //       child: const Center(child: Text("Start Now"))),
                    // )
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
