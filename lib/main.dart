import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/bingding/app_bingding.dart';
import 'package:xommoigarden/views/user/my_home_page.dart';

void main()  async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wejgdjjovslzuoxpnaby.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlamdkampvdnNsenVveHBuYWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NTQ1ODUsImV4cCI6MjA5MDEzMDU4NX0._f5muPb10BRqDv5_LpaVJFIMg50d0NmXaacyDiwglns',
  );
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Xóm Mới Garden', // tham so khoi tao theo ten cai tieu de app
      debugShowCheckedModeBanner: false,
      initialBinding: BindingApp(),

      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}
//
//
//
// lib/main.dart
// lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:xommoigarden/bingding/app_bingding.dart';
// import 'package:xommoigarden/views/pages/login_page.dart';
// import 'package:xommoigarden/views/pages/register_page.dart';
// import 'package:xommoigarden/views/user/add_address_page.dart';
// import 'package:xommoigarden/views/user/cart_page.dart';
// import 'package:xommoigarden/views/user/edit_profile_page.dart';
// import 'package:xommoigarden/views/user/my_home_page.dart';
// import 'package:xommoigarden/views/user/order_history_page.dart';
// import 'package:xommoigarden/views/user/order_success_page.dart';
// import 'package:xommoigarden/views/user/profile_page.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: 'https://wejgdjjovslzuoxpnaby.supabase.co',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlamdkampvdnNsenVveHBuYWJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NTQ1ODUsImV4cCI6MjA5MDEzMDU4NX0._f5muPb10BRqDv5_LpaVJFIMg50d0NmXaacyDiwglns',
//   );
//   await GetStorage.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Xóm Mới Garden',
//       debugShowCheckedModeBanner: false,
//       initialBinding: BindingApp(),
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
//         useMaterial3: true,
//       ),
//       getPages: [
//         GetPage(name: '/', page: () => MyHomePage()),
//         GetPage(name: '/login', page: () => LoginPage()),
//         GetPage(name: '/register', page: () => RegisterPage()),
//         GetPage(name: '/cart', page: () => CartPage()),
//         GetPage(name: '/profile', page: () => ProfilePage()),
//         GetPage(name: '/edit-profile', page: () => EditProfilePage()),
//         GetPage(name: '/order-history', page: () => OrderHistoryPage()),
//         GetPage(name: '/add-address', page: () => AddAddressPage()),
//         GetPage(name: '/order-success', page: () => OrderSuccessPage()),
//       ],
//       home: MyHomePage(),
//     );
//   }
// }