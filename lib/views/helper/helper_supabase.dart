import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
Future<String> uploadImage({required File image, required String bucket, required String path, bool upsert = false}) async{
  //gd1: tai len
  await supabase.storage.from("images").upload(
    path,
    image,
    fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false
    ),
  );
  //gd2: lay duong dan
  final String publicUrl = supabase
      .storage
      .from(bucket)
      .getPublicUrl(path);
  return publicUrl;
}

Future<String> updateImage({required File image, required String bucket, required String path, bool upsert = false}) async{
  //gd1: tai len
  await supabase.storage.from(bucket).update(
    path,
    image,
    fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: upsert
    ),
  );
  //gd2: lay duong dan
  //final String publicUrl = supabase
  String publicUrl = supabase
      .storage
      .from(bucket)
      .getPublicUrl(path);
  return publicUrl + "?ts=${DateTime.now().millisecond}"; // tra ve duong dan co gan theo thoi gian
}

Future<void> deleteImage({required String bucket, required String path}) async{
  final supabase = Supabase.instance.client;
  await supabase
      .storage
      .from(bucket)
      .remove([path]);
}

Future<Map<int, T>> getMapData<T>(
    {
      required String table,
      required T Function(Map<String, dynamic> map) fromMap,
      required int Function(T t) getId
    }) async{
  final supabase = Supabase.instance.client;
  var data = await supabase.from(table).select();
  var iterable = data.map(
        (e) => fromMap(e),
  );
  Map<int, T> _map = Map.fromIterable(
    iterable,
    key: (product) => getId(product),
    value: (product) => product,

    // key: (t) => getId(t),
    // value: (t) => t,
  );
  return _map;
}

Stream<List<T>> getDataStream<T>(
    {
      required String table,
      required List<String> ids,
      required T Function(Map<String, dynamic> map) fromMap
    }
    )
{
  var stream = supabase.from(table)
      .stream(primaryKey: ids);
  return stream.map(
        (maps) => maps.map(
          (e) => fromMap(e),
    ).toList(),
  );
}

//listenChange
ListenChangeData2<T>(
    Map<int, T> maps, {
      required String channel,
      required String schema,
      required String table,
      required T Function(Map<String, dynamic> map) fromMap,
      required int Function(T t) getId,
      Function()? updateUI,
    })
{
  //final supabase = Supabase.instance.client;
  supabase
      .channel(channel)
      .onPostgresChanges(
    //event: Sự kiện lắng nghe tất cả
    event: PostgresChangeEvent.all,
    schema: schema,
    table: table,
    callback: (payload) {
      switch(payload.eventType){
      //insert & update có: newRecord và oldRecord
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:{
          T t = fromMap(payload.newRecord);
          maps[getId(t)] = t;
          // Hàm gọi, ko gọi thì giá trị = null
          updateUI?.call();
          break;
        }
        case PostgresChangeEvent.delete:{
          maps.remove(payload.oldRecord["id"]);
          updateUI?.call();
          break;
        }
        default:{}
      }
    },
  ).subscribe();
}

class SupabaseAuthHelper {
  static final SupabaseClient client = Supabase.instance.client;

  /// Session hiện tại
  static Session? get response => client.auth.currentSession;

  /// User hiện tại
  static User? get user => response?.user;

  /// Metadata của user
  static Map<String, dynamic>? get meta => user?.userMetadata;
}
