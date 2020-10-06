import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:flutter_webrtc/webrtc.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

/*
 * callbacks for Signaling API.
 */
typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);
typedef void GroupStreamStateCallback(List<MediaStream> listOfStreams);

class GroupVoiceCallsHandler {
  Timer countdownTimer;
  var _peerConnections = new Map<String, RTCPeerConnection>();
  var _remoteCandidates = [];
  Map<String, List<dynamic>> _localCandidates = Map();
  List<MediaStreamTrack> _listOfStreams = [];
  Map<String, MediaStream> _remoteStreams = Map();
  Map<String, RTCSessionDescription> _pendingOffers = Map();
  SignalingStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  MediaStream _localStream;
  GroupStreamStateCallback onStreamListUpdate;
  OtherEventCallback onPeersUpdate;
  String _selfId = MyAppState.currentUser.userID;
  final bool isCaller;
  final HomeConversationModel homeConversationModel;
  List<dynamic> _membersJson = [];
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  StreamSubscription<DocumentSnapshot> messagesStreamSubscription;

  final String callerID;

  bool callStarted = false;
  bool callAnswered = false;

  bool didUserHangup = false;

  Timer timer;

  GroupVoiceCallsHandler(
      {@required this.isCaller,
      this.callerID,
      @required this.homeConversationModel});

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {
        'url': 'turn:95.217.132.49:80?transport=udp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
      {
        'url': 'turn:95.217.132.49:80?transport=tcp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };
  Map<String, StreamSubscription> mapOfUserListener = Map();

  void initCall(String peerID, BuildContext context) async {
    print('GroupVoiceCallsHandler.initCall init');
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }
    _localStream = await createStream();
    listenForMessages();
    homeConversationModel.members.forEach((element) {
      print('GroupVoiceCallsHandler.initCall ${element.fullName()}');
      _membersJson.add(element.toJson());
    });
    await Future.forEach(homeConversationModel.members,
        (User groupMember) async {
      print('GroupVoiceCallsHandler.initCall ${groupMember.fullName()} '
          '${homeConversationModel.members.length}');
      _createPeerConnection(getConnectionID(groupMember.userID))
          .then((pc) async {
        _peerConnections[getConnectionID(groupMember.userID)] = pc;
        if (isCaller) {
          await _createOffer(groupMember.userID, pc, context);
        }
      });
    });
    if (isCaller) {
      startCountDown(context);
      updateChat(context);
    }
  }

  startCallDurationTimer(VoidCallback callback(Timer timer)) {
    print('GroupVoiceCallsHandler.startCallDurationTimer');
    timer = Timer.periodic(Duration(seconds: 1), callback);
  }

  close() async {
    callAnswered = false;
    callStarted = false;
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }
    _peerConnections.forEach((key, pc) {
      pc.close();
    });

    mapOfUserListener.forEach((key, value) => value.cancel());
    if (messagesStreamSubscription != null) {
      messagesStreamSubscription.cancel();
    }
  }

  String getConnectionID(String friendID) {
    String connectionID;
    if (friendID.compareTo(this._selfId) < 0) {
      connectionID = friendID + this._selfId;
    } else {
      connectionID = this._selfId + friendID;
    }
    return connectionID;
  }

  void bye() async {
    print('VoiceCallsHandler.bye');
    if (isCaller && !callStarted) {
      await closeBeforeAnyoneAnswer();
    } else {
      print('GroupVoiceCallsHandler.bye callStarted');
      await FireStoreUtils.firestore
          .collection(USERS)
          .document(_selfId)
          .collection(CALL_DATA)
          .document(isCaller ? _selfId : callerID)
          .get(source: Source.server)
          .then((value) async {
        var byeRequest = value.data;
        print('GroupVoiceCallsHandler.bye then((value) async');
        byeRequest['hangup'] = true;
        byeRequest['connections'] =
            (value.data['connections'] as Map<String, dynamic>)..clear();

        DocumentReference documentReference = FireStoreUtils.firestore
            .collection(USERS)
            .document(_selfId)
            .collection(CALL_DATA)
            .document(isCaller ? _selfId : callerID);
        if (byeRequest != null) {
          await documentReference.setData(byeRequest);
          print('GroupVoiceCallsHandler.bye documentReference.setData'
              '(${byeRequest['connections']} ${byeRequest['hangup']})');
        } else {
          await documentReference.delete();
          print('GroupVoiceCallsHandler.bye documentReference.delete()');
        }
      });
    }
  }

  void onMessage(Map<String, dynamic> message, String connectionID) async {
    Map<String, dynamic> mapData = message;
    var connections = mapData['connections'];
    var data = connections[connectionID];
    if (isCaller || callStarted && callAnswered) {
      if (mapData.containsKey('hangup') &&
          (mapData['hangup'] ?? false) == true) {
        print('GroupVoiceCallsHandler.onMessage hangup');
        if (_peerConnections.containsKey(connectionID) &&
            _peerConnections[connectionID] != null) {
          _peerConnections[connectionID].close();
          _peerConnections[connectionID] = null;
          _peerConnections.remove(connectionID);
        }
        if (_remoteStreams.containsKey(connectionID) &&
            _remoteStreams[connectionID] != null) {
          _listOfStreams
              .remove(_remoteStreams[connectionID].getAudioTracks().first);
          _remoteStreams.remove(connectionID);
          if (this.onStreamListUpdate != null)
            this.onStreamListUpdate(_remoteStreams.values.toList());
        }
        print('GroupVoiceCallsHandler.onMessage ${_peerConnections.length}');
        if (_peerConnections.length == 1) {
          await _deleteMyCallFootprint();
        }
      }
    }
    print('GroupVoiceCallsHandler.onMessage $connectionID');
    if (data != null)
      switch (data['type']) {
        case 'offer':
          {
            var id = data['from'];
            if (id != _selfId) {
              print('VoiceCallsHandler.onMessage offer');
            } else {
              print('VoiceCallsHandler.onMessage you offered a call');
            }
            if (!isCaller) {
              await _onOfferReceivedFromOtherClient(
                  data['description'], connectionID);
            }
          }
          break;
        case 'answer':
          {
            var id = data['from'];

//          if (id != _selfId) {
            if (countdownTimer.isActive) countdownTimer.cancel();
            callStarted = true;
            callAnswered = true;
            print('VoiceCallsHandler.onMessage answer $connectionID');
            var description = data['description'];
            if (this.onStateChange != null)
              this.onStateChange(SignalingState.CallStateConnected);
            var pc = _peerConnections[connectionID];
            print('${pc == null} is null');
            if (pc != null) {
              await pc.setRemoteDescription(new RTCSessionDescription(
                  description['sdp'], description['type']));
            }

            await _sendCandidate(connectionID);
          }
          break;
        case 'candidate':
          {
            if (callStarted && callAnswered) {
              var id = data['from'];
              print('VoiceCallsHandler.onMessage candidate');
              List<dynamic> candidates = data['candidate'];
              var pc = _peerConnections[connectionID];
              await Future.forEach(candidates, (candidateMap) async {
                RTCIceCandidate candidate = new RTCIceCandidate(
                    candidateMap['candidate'],
                    candidateMap['sdpMid'],
                    candidateMap['sdpMLineIndex']);
                if (pc != null) {
                  await pc.addCandidate(candidate);
                } else {
                  _remoteCandidates.add(candidate);
                }
              });

              if (this.onStateChange != null)
                this.onStateChange(SignalingState.CallStateConnected);

              if (!isCaller) {
                await _sendCandidate(connectionID);
              }
            }
          }
          break;
        default:
          break;
      }
  }

  Future<MediaStream> createStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false
    };

    MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    if (this.onLocalStream != null) {
      this.onLocalStream(stream);
    }
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection(String connectionID) async {
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    pc.addStream(_localStream);
    _localCandidates[connectionID] = <dynamic>[];
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _localCandidates[connectionID].add(candidate.toMap());
    };
    pc.onAddStream = (stream) {
      _remoteStreams[connectionID] = stream;
      _listOfStreams.add(_remoteStreams[connectionID].getAudioTracks().first);
      if (this.onStreamListUpdate != null)
        this.onStreamListUpdate(_remoteStreams.values.toList());
    };
    pc.onRemoveStream = (stream) {
      _remoteStreams.values
          .toList()
          .removeWhere((MediaStream it) => it.id == stream.id);
      _listOfStreams.removeWhere((element) => element.id == stream.id);
      if (this.onStreamListUpdate != null)
        this.onStreamListUpdate(_remoteStreams.values.toList());
    };
    return pc;
  }

  _createOffer(String id, RTCPeerConnection pc, BuildContext context) async {
    try {
      RTCSessionDescription offer = await pc.createOffer(_constraints);
      pc.setLocalDescription(offer);
      await _sendOffer({
        'to': id,
        'from': _selfId,
        'description': {'sdp': offer.sdp, 'type': offer.type},
        'type': 'offer',
      }, context: context);
    } catch (e) {
      print(e.toString());
    }
  }

  _createAnswer(String id, RTCPeerConnection pc) async {
    try {
      RTCSessionDescription s = await pc.createAnswer(_constraints);
      pc.setLocalDescription(s);
      await _sendAnswer({
        'to': id.replaceAll(_selfId, ''),
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'type': 'answer',
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _sendOffer(Map<String, dynamic> data, {BuildContext context}) async {
    var request = new Map<String, dynamic>();
    print('GroupVoiceCallsHandler._sendOffer to ${data['to']} from $_selfId');
    request["connections"] = {getConnectionID(data['to']): data};
    if (isCaller) {
      request['type'] = 'offer';
      request['isGroupCall'] = true;
      request['callType'] = VOICE;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      await FireStoreUtils.firestore
          .collection(USERS)
          .document(data['to'])
          .collection(CALL_DATA)
          .getDocuments(source: Source.server)
          .then((value) async {
        if (value.documents.isEmpty) {
          await FireStoreUtils.firestore
              .collection(USERS)
              .document(data['to'])
              .collection(CALL_DATA)
              .document(_selfId)
              .setData(request);
        } else {
          showAlertDialog(context, 'Call', 'this user has an on-going call');
        }
      });
    } else {
      FireStoreUtils.firestore
          .collection(USERS)
          .document(_selfId)
          .collection(CALL_DATA)
          .document(callerID)
          .get(source: Source.server)
          .then((value) async {
        Map<String, dynamic> connections = value.data['connections'];
        connections[getConnectionID(data['to'])] = data;
        request["connections"] = connections;
        await FireStoreUtils.firestore
            .collection(USERS)
            .document(_selfId)
            .collection(CALL_DATA)
            .document(callerID)
            .setData(request, merge: true);
      });
    }
  }

  listenForMessages() {
    for (User member in homeConversationModel.members) {
      if (member.userID != _selfId) {
        Stream<DocumentSnapshot> messagesStream = FireStoreUtils.firestore
            .collection(USERS)
            .document(member.userID)
            .collection(CALL_DATA)
            .document(callerID)
            .snapshots();
        mapOfUserListener[getConnectionID(member.userID)] =
            messagesStream.listen((call) {
          print(
              'GroupVoiceCallsHandler.listenForMessages ${getConnectionID(member.userID)}');
          if (call != null && call.exists) {
            onMessage(call.data, getConnectionID(member.userID));
          } else {
            if (!isCaller &&
                !call.exists &&
                !callStarted &&
                getConnectionID(member.userID).contains(callerID)) {
              print('GroupVoiceCallsHandler.listenForMessages caller '
                  'hangup');
              if (!didUserHangup) {
                didUserHangup = true;
                countdownTimer.cancel();
                HomeScreen.onGoingCall = false;
                callStarted = false;
                callAnswered = false;
                if (this.onStateChange != null)
                  this.onStateChange(SignalingState.CallStateBye);
              }
            }
          }
        });
      }
    }
  }

  void startCountDown(BuildContext context) {
    print('VoiceCallsHandler.startCountDown');
    countdownTimer = new Timer(Duration(minutes: 1), () {
      print('VoiceCallsHandler.startCountDown periodic');
      bye();
      if (!isCaller) {
        print('FlutterRingtonePlayer _hangUp lets stop');
        FlutterRingtonePlayer.stop();
      }
      Navigator.of(context).pop();
    });
  }

  acceptCall(String sessionDescription, String sessionType) async {
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }
    callAnswered = true;
    String id = getConnectionID(callerID);
    RTCPeerConnection pc = _peerConnections[id];
    await pc.setRemoteDescription(
        new RTCSessionDescription(sessionDescription, sessionType));
    await _createAnswer(id, pc);
    await establishConnectionWithOtherClients();
    await respondToPendingOffers();
    if (this.onStateChange != null)
      this.onStateChange(SignalingState.CallStateConnected);
//    if (this._remoteCandidates.length > 0) {
//      _remoteCandidates.forEach((candidate) async {
//        await pc.addCandidate(candidate);
//      });
//      _remoteCandidates.clear();
//    }
  }

  _sendAnswer(Map<String, dynamic> data) async {
    callStarted = true;
    print('GroupVoiceCallsHandler._sendAnswer $_selfId ${data['to']}');
    var request = new Map<String, dynamic>();
    FireStoreUtils.firestore
        .collection(USERS)
        .document(_selfId)
        .collection(CALL_DATA)
        .document(callerID)
        .get(source: Source.server)
        .then((callDocument) async {
      Map<String, dynamic> connections =
          callDocument.data['connections'] ?? Map<String, dynamic>();
      connections[getConnectionID(data['to'])] = data;
      request['type'] = 'answer';
      request['isGroupCall'] = true;
      request['callType'] = VOICE;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      request['connections'] = connections;

      await FireStoreUtils.firestore
          .collection(USERS)
          .document(_selfId)
          .collection(CALL_DATA)
          .document(callerID)
          .setData(request, merge: true);
    });

//    _sendCandidate('candidate',
//        {'to': data['to'], 'from': _selfId, 'candidate': _localCandidates});
  }

  _sendCandidate(String connectionID) async {
    print('GroupVoiceCallsHandler._sendCandidate $connectionID');
    String receiverID = connectionID.replaceAll(_selfId, '');
    var request = new Map<String, dynamic>();
    var data = new Map<String, dynamic>();

    data['type'] = 'candidate';
    data['candidate'] = _localCandidates[connectionID];
    data['from'] = _selfId;
    data['to'] = receiverID;

    FireStoreUtils.firestore
        .collection(USERS)
        .document(isCaller ? receiverID : _selfId)
        .collection(CALL_DATA)
        .document(callerID)
        .get(source: Source.server)
        .then((value) async {
      Map<String, dynamic> connections =
          value.data['connections'] ?? Map<String, dynamic>();
      connections[connectionID] = data;
      request['type'] = 'candidate';
      request['isGroupCall'] = true;
      request['callType'] = VOICE;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      request['connections'] = connections;
      await FireStoreUtils.firestore
          .collection(USERS)
          .document(_selfId)
          .collection(CALL_DATA)
          .document(callerID)
          .setData(request);
    });
  }

  void updateChat(BuildContext context) async {
    MessageData message = MessageData(
        content: '${MyAppState.currentUser.fullName()} Started a Group Voice '
            'Call.',
        created: Timestamp.now(),
        senderFirstName: MyAppState.currentUser.firstName,
        senderID: MyAppState.currentUser.userID,
        senderLastName: MyAppState.currentUser.lastName,
        senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
        url: Url(mime: '', url: ''),
        videoThumbnail: '');

    await _fireStoreUtils.sendMessage(
        homeConversationModel.members,
        homeConversationModel.isGroupChat,
        message,
        homeConversationModel.conversationModel);
    homeConversationModel.conversationModel.lastMessageDate = Timestamp.now();
    homeConversationModel.conversationModel.lastMessage = message.content;

    await _fireStoreUtils
        .updateChannel(homeConversationModel.conversationModel);
  }

  closeBeforeAnyoneAnswer() async {
    print('GroupVoiceCallsHandler.closeBeforeAnyoneAnswer');
    await Future.forEach(homeConversationModel.members, (element) {
      FireStoreUtils.firestore
          .collection(USERS)
          .document(element.userID)
          .collection(CALL_DATA)
          .document(_selfId)
          .delete();
    });
  }

  establishConnectionWithOtherClients() {
    print('GroupVoiceCallsHandler.establishConnectionWithOtherClients');
    homeConversationModel.members.forEach((client) {
      String receiverID = client.userID;
      if (receiverID != callerID && _selfId.compareTo(receiverID) < 0) {
        print('GroupVoiceCallsHandler.establishConnectionWithOtherClients '
            'sending offer $_selfId $receiverID');
        FireStoreUtils.firestore
            .collection(USERS)
            .document(_selfId)
            .collection(CALL_DATA)
            .document(callerID)
            .get(source: Source.server)
            .then((value) async {
          Map<String, dynamic> connections = value.data['connections'];
          if (!connections.containsKey(getConnectionID(receiverID))) {
            RTCPeerConnection pc =
                _peerConnections[getConnectionID(receiverID)];
            RTCSessionDescription offer = await pc.createOffer(_constraints);
            pc.setLocalDescription(offer);
            await _sendOffer({
              'to': receiverID,
              'from': _selfId,
              'description': {'sdp': offer.sdp, 'type': offer.type},
              'type': 'offer',
            });
          }
        });
      }
    });
  }

  _deleteMyCallFootprint() async {
    print('GroupVoiceCallsHandler._deleteMyCallFootprint '
        '${homeConversationModel.members.length}');
    await Future.forEach(homeConversationModel.members, (member) async {
      print('GroupVoiceCallsHandler._deleteMyCallFootprint${member.userID}');
      await FireStoreUtils.firestore
          .collection(USERS)
          .document(member.userID)
          .collection(CALL_DATA)
          .document(isCaller ? _selfId : callerID)
          .delete();
      print('GroupVoiceCallsHandler._deleteMyCallFootprint ${member.userID}');
    });
    HomeScreen.onGoingCall = false;
    callStarted = false;
    callAnswered = false;
    if (this.onStateChange != null)
      this.onStateChange(SignalingState.CallStateBye);
  }

  _onOfferReceivedFromOtherClient(
      Map<String, dynamic> description, String connectionID) async {
    if (callAnswered) {
      RTCPeerConnection pc = _peerConnections[connectionID];
      await pc.setRemoteDescription(
          RTCSessionDescription(description['sdp'], description['type']));
      _createAnswer(connectionID, pc);
    } else {
      _pendingOffers[connectionID] =
          RTCSessionDescription(description['sdp'], description['type']);
    }
  }

  respondToPendingOffers() async {
    await Future.forEach(_pendingOffers.entries, (MapEntry element) async {
      print('GroupVoiceCallsHandler.respondToPendingOffers ${element.key}');
      RTCPeerConnection pc = _peerConnections[element.key];
      await pc?.setRemoteDescription(element.value);
      await _createAnswer(element.key, pc);
    });
  }
}
