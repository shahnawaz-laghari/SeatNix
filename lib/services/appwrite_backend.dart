import 'package:appwrite/appwrite.dart';

import '../config/appwrite_config.dart';

class AppwriteBackend {
  AppwriteBackend._();

  static final Client client = Client()
    ..setEndpoint(AppwriteConfig.endpoint)
    ..setProject(AppwriteConfig.projectId);

  static final Account account = Account(client);
  static final TablesDB tables = TablesDB(client);
  static final Storage storage = Storage(client);

  static bool get tripsConfigured =>
      AppwriteConfig.databaseId.isNotEmpty &&
      AppwriteConfig.tripsTableId.isNotEmpty;
}
