import 'package:flutter/widgets.dart';

enum EffectAnchorId {
  ticketBadge,
}

class EffectAnchorRegistry {
  EffectAnchorRegistry._();

  static final EffectAnchorRegistry instance = EffectAnchorRegistry._();

  final Map<EffectAnchorId, GlobalKey> _keys = {};

  void registerKey(EffectAnchorId id, GlobalKey key) {
    _keys[id] = key;
  }

  void unregister(EffectAnchorId id, GlobalKey key) {
    final current = _keys[id];
    if (current == key) {
      _keys.remove(id);
    }
  }

  Rect? getRect(EffectAnchorId id) {
    final key = _keys[id];
    final ctx = key?.currentContext;
    if (ctx == null) return null;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }
}

