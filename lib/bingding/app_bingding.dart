// lib/binding/app_binding.dart
import 'package:get/get.dart';
import 'package:xommoigarden/controller/address_controller.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/controller/product_controller.dart';
import 'package:xommoigarden/controller/profile_controller.dart';
import 'package:xommoigarden/controller/review_controller.dart';

class BindingApp extends Bindings {
  @override
  void dependencies() {
    // Auth controller - dùng chung toàn app
    Get.put(ControllerAuth(), permanent: true);

    // Product controller
    Get.lazyPut(() => ControllerProduct(), fenix: true);

    // Cart controller
    Get.lazyPut(() => ControllerCart(), fenix: true);

    // Order controller
    Get.lazyPut(() => ControllerOrder(), fenix: true);

    // Profile controller
    Get.lazyPut(() => ControllerProfile(), fenix: true);

    // Review controller
    Get.lazyPut(() => ControllerReview(), fenix: true);

    // Address controller - Thêm dòng này
    Get.lazyPut(() => ControllerAddress(), fenix: true);

    // Category controller - Thêm dòng này
    Get.lazyPut(() => CategoryController(), fenix: true);

    // Admin controller - Thêm dòng này
    Get.lazyPut(() => AdminController(), fenix: true);
  }
}