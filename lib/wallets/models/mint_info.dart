import 'dart:convert';
import 'package:isar/isar.dart';

part 'mint_info.g.dart';

/// NUTS support information
class NutsSupportInfo {
  NutsSupportInfo({
    required this.nutNum,
    this.methods = const [],
    this.supported = true,
    this.disabled = false,
  });

  static Set<int> get mandatoryNuts => {0, 1, 2, 3, 4, 5, 6};

  final int nutNum;
  final List<List<String>> methods;
  final bool supported;
  final bool disabled;

  factory NutsSupportInfo.fromServerJson(String nutNum, Map<String, dynamic> json) {
    final methods = <List<String>>[];
    final methodsRaw = json['methods'];
    if (methodsRaw is List) {
      for (var method in methodsRaw) {
        if (method is List) {
          methods.add(method.map((e) => e.toString()).toList());
        }
      }
    }

    return NutsSupportInfo(
      nutNum: int.tryParse(nutNum) ?? 0,
      methods: methods,
      supported: json['supported'] ?? true,
      disabled: json['disabled'] ?? false,
    );
  }

  @override
  String toString() {
    return 'NutsSupportInfo(nutNum: $nutNum, methods: $methods, supported: $supported, disabled: $disabled)';
  }
}

/// Mint information model for Isar database
@collection
class MintInfo {
  MintInfo({
    required this.mintURL,
    required this.name,
    required this.pubkey,
    required this.version,
    required this.description,
    required this.descriptionLong,
    required this.contactJsonRaw,
    required this.motd,
    required this.nutsJsonRaw,
  }) {
    var contactRaw = <dynamic>[];
    var nutsRaw = <String, dynamic>{};

    try {
      contactRaw = json.decode(contactJsonRaw);
      nutsRaw = json.decode(nutsJsonRaw);
    } catch (_) {}

    // Parse contact information
    for (var entry in contactRaw) {
      if (entry is List && entry.length > 1) {
        contact.add(entry.map((e) => e.toString()).toList());
      }
    }

    // Parse NUTS information
    nutsRaw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        nutsInfo.add(NutsSupportInfo.fromServerJson(key, value));
      }
    });

    nutsInfo.sort((a, b) => a.nutNum - b.nutNum);
  }

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String mintURL;
  late String name;
  late String pubkey;
  late String version;
  late String description;
  late String descriptionLong;

  late String contactJsonRaw;
  @Ignore()
  List<List<String>> contact = [];

  late String motd;

  late String nutsJsonRaw;
  @Ignore()
  List<NutsSupportInfo> nutsInfo = [];

  /// Create from server response
  factory MintInfo.fromServerMap(Map<String, dynamic> jsonMap, String mintURL) {
    var nuts = <String, dynamic>{};
    final nutsRaw = jsonMap['nuts'];
    if (nutsRaw is Map) {
      nuts = nutsRaw.cast<String, dynamic>();
    } else if (nutsRaw is List) {
      nuts = nutsRaw.fold(<String, Map<String, dynamic>>{}, (pre, e) {
        pre[e.toString()] = {};
        return pre;
      });
    }

    String contactJsonRaw = '';
    String nutsJsonRaw = '';
    try {
      contactJsonRaw = json.encode(jsonMap['contact'] ?? []);
      nutsJsonRaw = json.encode(nuts);
    } catch (_) {}

    return MintInfo(
      mintURL: mintURL,
      name: jsonMap['name']?.toString() ?? '',
      pubkey: jsonMap['pubkey']?.toString() ?? '',
      version: jsonMap['version']?.toString() ?? '',
      description: jsonMap['description']?.toString() ?? '',
      descriptionLong: jsonMap['description_long']?.toString() ?? '',
      contactJsonRaw: contactJsonRaw,
      motd: jsonMap['motd']?.toString() ?? '',
      nutsJsonRaw: nutsJsonRaw,
    );
  }

  @override
  String toString() {
    return 'MintInfo(name: $name, pubkey: $pubkey, version: $version)';
  }
}
