import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Position? position;
// Future<bool> _handlePermission() async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   // Test if location services are enabled.
//   serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     // Location services are not enabled don't continue
//     // accessing the position and request users of the
//     // App to enable the location services.
//     _updatePositionList(
//       _PositionItemType.log,
//       _kLocationServicesDisabledMessage,
//     );

//     return false;
//   }

//   permission = await _geolocatorPlatform.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await _geolocatorPlatform.requestPermission();
//     if (permission == LocationPermission.denied) {
//       // Permissions are denied, next time you could try
//       // requesting permissions again (this is also where
//       // Android's shouldShowRequestPermissionRationale
//       // returned true. According to Android guidelines
//       // your App should show an explanatory UI now.
//       _updatePositionList(
//         _PositionItemType.log,
//         _kPermissionDeniedMessage,
//       );

//       return false;
//     }
//   }

//   // if (permission == LocationPermission.deniedForever) {
//   //   // Permissions are denied forever, handle appropriately.
//   //   _updatePositionList(
//   //     _PositionItemType.log,
//   //     _kPermissionDeniedForeverMessage,
//   //   );

//   //   return false;
//   // }

//   // When we reach here, permissions are granted and we can
//   // continue accessing the position of the device.
//   // _updatePositionList(
//   //   _PositionItemType.log,
//   //   _kPermissionGrantedMessage,
//   // );
//   // return true;
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  await _geolocatorPlatform.isLocationServiceEnabled();
  await _geolocatorPlatform.requestPermission();
  position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MapsScreen(),
    );
  }
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final CameraPosition _initialCameraPosition =
      const CameraPosition(target: LatLng(70, 88.43), zoom: 11.5);
  GoogleMapController? _googleMapController;
  BitmapDescriptor? image;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero).then((value) async {
      await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, " assetName");
    });
  }

  getImage() async {
    return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, " assetName");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _googleMapController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: false,
        markers: {
          Marker(
              markerId: const MarkerId("1"),
              infoWindow: const InfoWindow(title: "Starting Point"),
              position: LatLng(position!.latitude, position!.longitude)),
          Marker(
              markerId: const MarkerId("2"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan),
              infoWindow: const InfoWindow(title: "2 PIT HOle"),
              position:
                  LatLng(position!.latitude + .1, position!.longitude + .1)),
          Marker(
              markerId: const MarkerId("3"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan),
              infoWindow: const InfoWindow(title: "3 PIT HOle"),
              position:
                  LatLng(position!.latitude + .2, position!.longitude + .2)),
          Marker(
              markerId: const MarkerId("4"),
              infoWindow: const InfoWindow(title: "4 PIT HOle"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan),
              position:
                  LatLng(position!.latitude + .3, position!.longitude + .3))
        },
        zoomControlsEnabled: false,
        onMapCreated: (controller) => _googleMapController = controller,
        initialCameraPosition: _initialCameraPosition,
      ),
    );
  }
}
