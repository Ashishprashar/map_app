import 'dart:async';
import 'dart:math';
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
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_app/place_service.dart';
import 'package:map_app/secrets.dart';
import 'package:uuid/uuid.dart';

import 'address_search.dart';

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
            // soundSource: 'assets/notification.m4a',
            playSound: false,
            channelName: 'Basic notifications',
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
  final assetsAudioPlayer = AssetsAudioPlayer();

  final loc.Location _locationTracker = loc.Location();
  Marker? marker;
  double rotation = 0.0;
  Circle? circle;
  GoogleMapController? _controller;
  final positionCollection = FirebaseFirestore.instance.collection("positions");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static CameraPosition initialLocation = const CameraPosition(
    target: LatLng(12.87, 77.54),
    zoom: 14.4746,
  );
  var imageDataBreaker;
  @override
  initState() {
    super.initState();
    assetsAudioPlayer.open(
      Audio("assets/notification.mp3"),
    );
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
        await DefaultAssetBundle.of(context).load("assets/bike_icon.png");
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
    assetsAudioPlayer.play();
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

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return SizedBox(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        onTap: () async {
          final sessionToken = const Uuid().v4();
          final Suggestion? result = await showSearch(
            context: context,
            delegate: AddressSearch(sessionToken),
          );
          if (result != null) {
            locationCallback(result.description);
            controller.text = result.description;
          }
        },
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  // Method for retrieving the address
  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      // Use the retrieved coordinates of the current position,
      // instead of the address if the start position is user's
      // current position, as it results in better accuracy.
      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition.latitude
          : startPlacemark[0].latitude;

      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      // Start Location Marker
      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Destination Location Marker
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding the markers to the list
      markersList.add(startMarker);
      markersList.add(destinationMarker);

      print(
        'START COORDINATES: ($startLatitude, $startLongitude)',
      );
      print(
        'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
      );

      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      // Calculating the distance between the start and the end positions
      // with a straight path, without considering any route
      // double distanceInMeters = await Geolocator.bearingBetween(
      //   startLatitude,
      //   startLongitude,
      //   destinationLatitude,
      //   destinationLongitude,
      // );

      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude);

      double totalDistance = 0.0;

      // Calculating the total distance by adding the distance
      // between small segments
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
        print('DISTANCE: $_placeDistance km');
      });

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _getCurrentLocation();
  // }

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
              polylines: Set<Polyline>.of(polylines.values),
              markers: Set.of((marker != null)
                  ? [
                      marker!,
                      for (var i = 0; i < positionsList.length; i++)
                        ...[
                              Marker(
                                  markerId: MarkerId(i.toString()),
                                  position: LatLng(positionsList[i].latitude,
                                      positionsList[i].longitude),
                                  rotation: rotation,
                                  draggable: false,
                                  zIndex: 2,
                                  infoWindow: const InfoWindow(
                                    title: 'Speed Breaker',
                                    // snippet: _destinationAddress,
                                  ),
                                  flat: true,
                                  anchor: const Offset(0.5, 0.5),
                                  icon: BitmapDescriptor.fromBytes(
                                      imageDataBreaker))
                            ] +
                            markersList
                    ]
                  : [
                        for (var i = 0; i < positionsList.length; i++) ...[
                          Marker(
                              markerId: MarkerId(i.toString()),
                              position: LatLng(positionsList[i].latitude,
                                  positionsList[i].longitude),
                              rotation: rotation,
                              infoWindow: const InfoWindow(
                                title: 'Speed Breaker',
                                // snippet: _destinationAddress,
                              ),
                              draggable: false,
                              zIndex: 2,
                              flat: true,
                              anchor: const Offset(0.5, 0.5),
                              icon:
                                  BitmapDescriptor.fromBytes(imageDataBreaker))
                        ]
                      ] +
                      markersList),
              circles: Set.of((circle != null) ? [circle!] : []),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Places',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Start',
                              hint: 'Choose starting point',
                              prefixIcon: const Icon(Icons.looks_one),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: () {
                                  startAddressController.text = _currentAddress;
                                  _startAddress = _currentAddress;
                                },
                              ),
                              controller: startAddressController,
                              focusNode: startAddressFocusNode,
                              width: width,
                              locationCallback: (String value) async {
                                setState(() {
                                  _startAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Destination',
                              hint: 'Choose destination',
                              prefixIcon: const Icon(Icons.looks_two),
                              controller: destinationAddressController,
                              focusNode: desrinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) async {
                                setState(() {
                                  _destinationAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'DISTANCE: $_placeDistance km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: (_startAddress != '' &&
                                    _destinationAddress != '')
                                ? () async {
                                    startAddressFocusNode.unfocus();
                                    desrinationAddressFocusNode.unfocus();
                                    setState(() {
                                      if (markers.isNotEmpty) markers.clear();
                                      if (polylines.isNotEmpty) {
                                        polylines.clear();
                                      }
                                      if (polylineCoordinates.isNotEmpty) {
                                        polylineCoordinates.clear();
                                      }
                                      _placeDistance = null;
                                    });

                                    _calculateDistance().then((isCalculated) {
                                      if (isCalculated) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Distance Calculated Sucessfully'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Error Calculating Distance'),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Show Route'.toUpperCase(),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
        //   floatingActionButton: FloatingActionButton(
        //       child: const Icon(Icons.location_searching),
      ),
    );
  }
}
