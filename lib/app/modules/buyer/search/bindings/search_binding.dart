import 'package:get/get.dart';
import '../controllers/search_controller.dart' as search;

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<search.SearchController>(
      () => search.SearchController(),
    );
  }
}
