import 'dart:convert';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

extension RoomExtension on Room {
  RecentChatSearchModel toRecentChatSearchModel(
    MatrixLocalizations matrixLocalizations,
  ) {
    return RecentChatSearchModel(
      id,
      displayName: getLocalizedDisplayname(matrixLocalizations),
      roomSummary: summary,
      directChatMatrixID: directChatMatrixID,
    );
  }

  bool isNotSpaceAndStoryRoom() {
    return !isSpace && !isStoryRoom;
  }

  bool isShowInChatList() {
    return _isDirectChatHaveMessage() || _isGroupChat();
  }

  bool _isGroupChat() {
    return !isDirectChat;
  }

  bool _isDirectChatHaveMessage() {
    return isDirectChat && _isLastEventInRoomIsMessage();
  }

  bool _isLastEventInRoomIsMessage() {
    return [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
    ].contains(lastEvent?.type);
  }

  Future<void> mute() async {
    await setPushRuleState(PushRuleState.mentionsOnly);
  }

  Future<void> unmute() async {
    await setPushRuleState(PushRuleState.notify);
  }

  bool get isMuted {
    return pushRuleState != PushRuleState.notify;
  }

  String storePlaceholderFileInMem({
    required FileInfo fileInfo,
    String? txid,
  }) {
    txid ??= client.generateUniqueTransactionId();
    final matrixFile = MatrixFile.fromFileInfo(
      fileInfo: fileInfo,
    );
    sendingFilePlaceholders[txid] = matrixFile;
    return txid;
  }

  bool get isInvitation {
    return membership == Membership.invite;
  }

  bool get canPinMessage {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomPinnedEvents) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canSendReactions {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Reaction) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeRoomName {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomName) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeTopic {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomTopic) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeRoomAvatar {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomAvatar) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canEnableEncryption {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Encryption) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canEditChatDetails {
    return canChangeRoomName ||
        canChangeTopic ||
        canChangeRoomAvatar ||
        canEnableEncryption ||
        canChangePowerLevel;
  }

  bool get canSendRedactEvent {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Redaction) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canRedactEventSentByOther {
    if (!canSendRedactEvent) return false;
    return canRedact;
  }

  Future<Event?> lastEventAvailableInPreview(BuildContext context) async {
    // as lastEvent calculation is based on the state events we unfortunately cannot
    // use sortOrder here: With many state events we just know which ones are the
    // newest ones, without knowing in which order they actually happened. As such,
    // using the origin_server_ts is the best guess for this algorithm. While not
    // perfect, it is only used for the room preview in the room list and sorting
    // said room list, so it should be good enough.
    Event? lastEventAvailableInPreview;
    try {
      final lastEvents =
          client.roomPreviewLastEvents.map(getState).whereType<Event>();

      lastEventAvailableInPreview = lastEvents.isEmpty
          ? null
          : lastEvents.reduce((a, b) {
              if (AppConfig.hideRedactedEvents) {
                if (a.redacted) return b;
                if (b.redacted) return a;
              }
              if (a.originServerTs == b.originServerTs) {
                // if two events have the same sort order we want to give encrypted events a lower priority
                // This is so that if the same event exists in the state both encrypted *and* unencrypted,
                // the unencrypted one is picked
                return a.type == EventTypes.Encrypted ? b : a;
              }
              return a.originServerTs.millisecondsSinceEpoch >
                      b.originServerTs.millisecondsSinceEpoch
                  ? a
                  : b;
            });

      print(
          'lastEventAvailableInPreview datph at 1 room: ${getLocalizedDisplayname(MatrixLocals(L10n.of(context)!))} lastEvent : ${jsonEncode(lastEventAvailableInPreview)}');

      if (lastEventAvailableInPreview == null ||
          (AppConfig.hideRedactedEvents && lastEventAvailableInPreview.redacted)) {
        final lastState = _getLastestRoomState();

        if (lastState == null) return null;

        lastEventAvailableInPreview = lastState;
        final messageEvents =
            await client.database?.getEventList(this, limit: 10);
        if (messageEvents == null || messageEvents.isEmpty) {
          return lastState;
        }

        for (final messageEvent in messageEvents) {
          // print(
          //     'lastEventAvailableInPreview datph at room: ${getLocalizedDisplayname(
          //   MatrixLocals(L10n.of(context)!),
          // )} messageEvent time: ${messageEvent.originServerTs} - lastState time: ${lastState.originServerTs}');

          // print(
          //     'lastEventAvailableInPreview datph at room: ${getLocalizedDisplayname(
          //   MatrixLocals(L10n.of(context)!),
          // )} should hide redact ${_shouldHideRedactedEvents(messageEvent)}');

          print(
              'lastEventAvailableInPreview datph at room: ${getLocalizedDisplayname(
            MatrixLocals(L10n.of(context)!),
          )} config hide ${AppConfig.hideRedactedEvents} - message redacted: ${messageEvent.redacted} - message: ${jsonEncode(messageEvent)}');
          if (_shouldHideRedactedEvents(messageEvent)) continue;

          if (messageEvent.originServerTs.millisecondsSinceEpoch >
              lastState.originServerTs.millisecondsSinceEpoch) {
            print(
                'lastEventAvailableInPreview datph at room: ${getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            )} datph change ');
            lastEventAvailableInPreview = messageEvent;
            break;
          }
        }
      }
    } catch (e) {
      Logs().e('Room::lastEventAvailableInPreview: room: $id error - $e');
      return null;
    }

    print('lastEventAvailableInPreview datph at room: ${getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    )} last EVENT = ${jsonEncode(lastEventAvailableInPreview)}');
    return lastEventAvailableInPreview;
  }

  bool _shouldHideRedactedEvents(Event event) {
    return AppConfig.hideRedactedEvents && event.redacted;
  }

  Event? _getLastestRoomState() {
    var lastTime = DateTime.fromMillisecondsSinceEpoch(0);
    Event? lastState;
    states.forEach((final String key, final entry) {
      final state = entry[''];
      if (state == null) return;
      if (AppConfig.hideRedactedEvents && state.redacted) return;
      if (state.originServerTs.millisecondsSinceEpoch >
          lastTime.millisecondsSinceEpoch) {
        lastTime = state.originServerTs;
        lastState = state;
      }
    });
    return lastState;
  }
}
