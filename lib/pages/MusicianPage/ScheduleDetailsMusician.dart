import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerCifraUser.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerLetra.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerLetraUser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart'; // Pacote para reproduzir som (adicionar no pubspec.yaml)

class AudioPlayerBottomSheet extends StatefulWidget {
  final String documentId; // Use documentId to fetch lyrics from Firestore

  AudioPlayerBottomSheet({
    required this.documentId, // Update parameter to use documentId
  });

  @override
  _AudioPlayerBottomSheetState createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> playbackSpeedOptions = [
    {'label': '0.5x', 'value': 0.5},
    {'label': '0.75x', 'value': 0.75},
    {'label': 'Normal', 'value': 1.0}, // Default speed
    {'label': '1.25x', 'value': 1.25},
    {'label': '1.5x', 'value': 1.5},
    {'label': '1.75x', 'value': 1.75},
    {'label': '2.0x', 'value': 2.0},
  ];
  bool isUserScrolling = false; // Track if the user is scrolling manually
  bool isAutoScrollEnabled = true; // New state to control auto-scrolling
  late ScrollController _scrollController; // Add this line
  bool isExpanded = false; // Estado de expansão
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  late TabController _tabController;
  bool showTimeline = false; // New state to control timeline visibility
  double playbackSpeed = 1.0; // Variable to track playback speed
  late StreamSubscription<Duration> positionSubscription;
  late StreamSubscription<PlayerState> playerStateSubscription;
  late StreamSubscription<Duration> durationSubscription;

  List<Map<String, dynamic>> lyrics = []; // Store lyrics with timestamps
  late int currentLyricIndex; // To track the current lyric index

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController(); // Initialize the scroll controller

    fetchLyrics();

    positionSubscription =
        audioPlayer.onPositionChanged.listen((Duration newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
          updateCurrentLyric(); // Update the current lyric based on position
        });
      }
    });

    durationSubscription =
        audioPlayer.onDurationChanged.listen((Duration newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    playerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        setState(() {
          isUserScrolling = true;
        });
      } else if (isUserScrolling) {
        // Wait a bit before resetting to false to allow any slight manual scrolling to complete
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              isUserScrolling = false;
            });
          }
        });
      }
    });
    playAudio();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (mounted) {
          setState(() {
            showTimeline =
                _tabController.index == 1; // Show timeline only on Lyrics tab
          });
        }
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _tabController.dispose();
    positionSubscription.cancel();
    playerStateSubscription.cancel();
    durationSubscription.cancel();
    super.dispose();
    _scrollController.dispose(); // Dispose of the scroll controller
  }

  void fetchLyrics() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lrcs')
          .where('lyrics_id', isEqualTo: widget.documentId)
          .orderBy('timestamp')
          .get();

      setState(() {
        lyrics = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'timestamp': Duration(milliseconds: data['timestamp'] ?? 0),
            'lyric': data['lyric'] ?? '',
          };
        }).toList();
        currentLyricIndex = 0; // Initialize the index
      });
    } catch (e) {
      print('Error fetching lyrics: $e');
    }
  }

  void playAudio() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play(AssetSource("redentor.mp3"));
        await audioPlayer
            .setPlaybackRate(playbackSpeed); // Set initial playback speed
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void stopAudio() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  void seekAudio(Duration newPosition) async {
    try {
      await audioPlayer.seek(newPosition);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  void _onSeekBarTap(TapDownDetails details, BoxConstraints constraints) {
    final double relativeX = details.localPosition.dx;
    final double width = constraints.maxWidth;
    final double newPosition = (relativeX / width) * duration.inSeconds;
    seekAudio(Duration(seconds: newPosition.toInt()));
  }

  void updateCurrentLyric() {
    if (lyrics.isNotEmpty) {
      for (int i = 0; i < lyrics.length; i++) {
        final lyricTimestamp = lyrics[i]['timestamp'];
        if (position >= lyricTimestamp) {
          setState(() {
            currentLyricIndex = i;
          });
          // Scroll to keep the current lyric in view
          _scrollToCurrentLyric();
        } else {
          break;
        }
      }
    }
  }

  void _scrollToCurrentLyric() {
    if (_scrollController.hasClients && isAutoScrollEnabled) {
      // Only scroll if auto-scrolling is enabled
      if (currentLyricIndex < lyrics.length - 0) {
        final offset =
            currentLyricIndex * 60.0; // Adjust according to your needs
        _scrollController.animateTo(
          offset,
          duration: Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    }
  }

  // Function to increase playback speed
  void increasePlaybackSpeed() {
    setState(() {
      if (playbackSpeed < 2.0) {
        playbackSpeed += 0.25;
        audioPlayer.setPlaybackRate(playbackSpeed);
      }
    });
  }

  // Function to decrease playback speed
  void decreasePlaybackSpeed() {
    setState(() {
      if (playbackSpeed > 0.5) {
        playbackSpeed -= 0.25;
        audioPlayer.setPlaybackRate(playbackSpeed);
      }
    });
  }

  // Function to reset playback speed to normal
  void resetPlaybackSpeed() {
    setState(() {
      playbackSpeed = 1.0;
      audioPlayer.setPlaybackRate(playbackSpeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Player'),
                  Tab(text: 'Lyrics'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Player Tab
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 24),
                          /*
                          Container(
                            decoration: BoxDecoration(color: Colors.white),
                            height: 12,
                            child: LinearProgressIndicator(
                              value: duration.inSeconds > 0
                                  ? position.inSeconds / duration.inSeconds
                                  : 0.0,
                              backgroundColor: Colors.grey[600],
                              color: Colors.white,
                            ),
                          ),*/
                          Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(color: Colors.grey),
                            child: Icon(
                              Icons.music_note,
                              size: 87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Speed:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              DropdownButton<double>(
                                padding: EdgeInsets.zero,
                                value: playbackSpeed,
                                dropdownColor: Colors.black,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                onChanged: (double? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      playbackSpeed = newValue;
                                      audioPlayer
                                          .setPlaybackRate(playbackSpeed);
                                    });
                                  }
                                },
                                items: playbackSpeedOptions.map((speedOption) {
                                  return DropdownMenuItem<double>(
                                    value: speedOption['value'],
                                    child: Text(
                                      speedOption['label'],
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 12,
                          ),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                onTapDown: (details) =>
                                    _onSeekBarTap(details, constraints),
                                onHorizontalDragUpdate: (details) =>
                                    _onSeekBarTap(
                                        details as TapDownDetails, constraints),
                                child: Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: FractionallySizedBox(
                                          widthFactor: duration.inSeconds > 0
                                              ? position.inSeconds /
                                                  duration.inSeconds
                                              : 0.0,
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 5),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white),
                              ),
                              Text(
                                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          SizedBox(height: 33),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Function to rewind or change BPM
                                },
                                child: Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: playAudio,
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Function to fast forward or change BPM
                                },
                                child: Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Playback speed controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [],
                          ),
                          SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      isExpanded
                                          ? 'Ocultar Letra'
                                          : 'Mostrar Letra',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Visibility(
                                  visible: isExpanded,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isAutoScrollEnabled =
                                            !isAutoScrollEnabled;
                                      });
                                    },
                                    child: Text(
                                      isAutoScrollEnabled
                                          ? 'Disable Auto-Scroll'
                                          : 'Enable Auto-Scroll',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Visibility(
                            visible: isExpanded,
                            child: Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: lyrics.length,
                                  itemBuilder: (context, index) {
                                    final lyricData = lyrics[index];
                                    final lyric = lyricData['lyric'] as String;
                                    final isCurrent =
                                        index == currentLyricIndex;
                                    var i = index++;

                                    return AnimatedOpacity(
                                      opacity: isCurrent ? 1.0 : 0.5,
                                      duration: Duration(milliseconds: 300),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lyric,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontSize: isCurrent ? 24 : 16,
                                              color: isCurrent
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.7),
                                              fontWeight: isCurrent
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          SizedBox(
                                            height: isCurrent ? 40 : 20,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Lyrics T
                    // ab

                    // Lyrics Tab
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isAutoScrollEnabled = !isAutoScrollEnabled;
                              });
                            },
                            child: Text(isAutoScrollEnabled
                                ? 'Disable Auto-Scroll'
                                : 'Enable Auto-Scroll'),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: lyrics.length,
                              itemBuilder: (context, index) {
                                final lyricData = lyrics[index];
                                final lyric = lyricData['lyric'] as String;
                                final isCurrent = index == currentLyricIndex;

                                return Hero(
                                  tag: 'hero-lyrics-$index',
                                  child: AnimatedOpacity(
                                    opacity: isCurrent ? 1.0 : 0.5,
                                    duration: Duration(milliseconds: 300),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lyric,
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: isCurrent
                                                ? 24
                                                : 16, // Larger font for the current lyric
                                            color: isCurrent
                                                ? Colors.white
                                                : Colors.white.withOpacity(
                                                    0.7), // Less opacity for non-current lyrics
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        SizedBox(
                                          height: isCurrent
                                              ? 40
                                              : 20, // Extra space below the current lyric for emphasis
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showPlayerBlurBottomSheet(BuildContext context, String audioUrl,
    String musica, String author, String lyrics, String documentId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled:
        true, // Allows the sheet to be taller than the default height
    showDragHandle: true,
    builder: (BuildContext context) {
      return Container(
        child: AudioPlayerBottomSheet(
          documentId: documentId,
        ),
      );
    },
  );
}

class BPMBottomSheet extends StatefulWidget {
  final int bpm;

  BPMBottomSheet({required this.bpm});

  @override
  _BPMBottomSheetState createState() => _BPMBottomSheetState();
}

class _BPMBottomSheetState extends State<BPMBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  Timer? _timer;
  int _bpm = 0;
  AudioPlayer _audioPlayer = AudioPlayer();
  Function()? onTick;

  @override
  void initState() {
    super.initState();

    _bpm = widget.bpm;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / _bpm).toInt()),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        if (mounted) {
          // Ensure the widget is still in the tree before calling setState
          setState(() {});
        }
      });

    audioPlayer = AudioPlayer();
    audioPlayer.onDurationChanged.listen((Duration newDuration) {
      if (mounted) {
        // Ensure the widget is still in the tree before calling setState
        setState(() {
          duration = newDuration;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((Duration newPosition) {
      if (mounted) {
        // Ensure the widget is still in the tree before calling setState
        setState(() {
          position = newPosition;
        });
      }
    });

    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        // Ensure the widget is still in the tree before calling setState
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  void start(int bpm) {
    print("Selecionado: " + bpm.toString());
    _bpm = bpm;
    final interval = Duration(milliseconds: (60000 / bpm).toInt());

    _timer?.cancel(); // Cancel any existing timer

    _timer = Timer.periodic(interval, (timer) async {
      if (!mounted) return; // Check if the widget is still mounted
      if (onTick != null) onTick!();
      await _playClickSound(); // Play metronome click sound
      print("Tocando");
      print("Intervalo " + interval.inMilliseconds.toString());
    });

    _animationController.duration =
        Duration(milliseconds: (60000 / _bpm).toInt());
    _animationController.repeat(reverse: true); // Start animation
  }

  void stop() {
    _timer?.cancel();
    _animationController.stop(); // Stop the animation
  }

  void setBpm(int bpm) {
    _bpm = bpm;
    start(_bpm); // Restart the timer with the new BPM

    // Update the animation duration based on the new BPM
    _animationController.duration =
        Duration(milliseconds: (60000 / _bpm).toInt());
    _animationController.repeat(
        reverse: true); // Repeat the animation back and forth
  }

  Future<void> _playClickSound() async {
    try {
      await _audioPlayer.stop(); // Stop any current sound
      await _audioPlayer
          .play(AssetSource('click.mp3')); // Play the metronome click sound
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if it's running
    _animationController.dispose(); // Dispose of the animation controller
    audioPlayer.dispose(); // Dispose of the audio player
    super.dispose();
  }

  // Helper method to build a static ball
  Widget _buildStaticBall() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  // Helper method to build the moving ball
  Widget _buildMovingBall() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              (MediaQuery.of(context).size.width / 3) *
                  (_animation.value - 0.5) *
                  2,
              0), // Move left and right
          child: child,
        );
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('BPM atual: $_bpm');
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply blur
        child: Container(
          color: Colors.black.withOpacity(0.8), // Semi-transparent background
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Metrônomo',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 20),
              // Animation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStaticBall(), // Left static ball
                  _buildMovingBall(), // Animated moving ball
                  _buildStaticBall(), // Right static ball
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bpm--; // Decrement BPM
                        setBpm(_bpm);
                      });
                    },
                    child: Icon(
                      Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_bpm BPM',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bpm++; // Increment BPM
                        setBpm(_bpm);
                      });
                    },
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (_timer == null || !_timer!.isActive) {
                    start(_bpm); // Start metronome
                    print('Metrônomo iniciado a $_bpm BPM');
                  } else {
                    stop(); // Stop metronome
                    print('Metrônomo parado');
                  }
                },
                child: Text(
                  'Play/Pause',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  stop(); // Stop the metronome
                  Navigator.pop(context); // Close the Bottom Sheet
                },
                child: Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openMetronome(BuildContext context, int bpm) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return BPMBottomSheet(
        bpm: bpm,
      );
    },
  );
}

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

class ScheduleDetailsMusician extends StatefulWidget {
  final String id;

  const ScheduleDetailsMusician({
    required this.id,
  });

  @override
  State<ScheduleDetailsMusician> createState() =>
      _ScheduleDetailsMusicianState();
}

class _ScheduleDetailsMusicianState extends State<ScheduleDetailsMusician> {
  void _openYouTubeLink(String? link) async {
    if (link == null || link.isEmpty) {
      // Exibir uma mensagem ou fazer nada se o link for nulo ou vazio
      return;
    }

    final uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o URL: $link';
    }
  }

  Future<void> _launchInBrowser(String url) async {
    if (!await launch(
      url,
      forceSafariVC: true,
      forceWebView: false,
      headers: <String, String>{'my_header_key': 'my_header_value'},
    )) {
      throw 'Could not launch $url';
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late int currentIndex;
  List<Map<String, dynamic>> musicos = [];
  String selectedMenu = 'Musicas';
  Map<String, dynamic>? cultoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // currentIndex = widget.currentIndex;
    //_loadInitialData(); // Carrega os dados iniciais ao iniciar
  }

  Future<List<Map<String, dynamic>>> _getUserCultoInstruments(
      String cultoId) async {
    try {
      // Buscar os documentos de user_culto_instrument para o culto atual
      QuerySnapshot userCultoInstrumentsSnapshot = await _firestore
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: cultoId)
          .get();

      List<Map<String, dynamic>> userCultoInstrumentsData = [];

      for (var doc in userCultoInstrumentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int userId = data['idUser'];
        print(userId);

        // Buscar o nome do usuário
        QuerySnapshot userSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> userData =
              userSnapshot.docs.first.data() as Map<String, dynamic>;
          data['name'] = userData['name'] ?? 'Nome não encontrado';
          data['user_id'] = userData['user_id'] ?? 'ID não encontrado';
          data['photoUrl'] = userData['photoUrl'] ?? 'ID não encontrado';
          print(userData['name']);
        } else {
          data['name'] = 'Nome não encontrado';
          data['user_id'] = 'ID não encontrado';
          data['photoUrl'] = 'ID não encontrado';
        }

        userCultoInstrumentsData.add(data);
      }

      return userCultoInstrumentsData;
    } catch (e) {
      print('Erro ao buscar dados da coleção user_culto_instrument: $e');
      throw e;
    }
  }

  int bpm = 145;

  Future<Map<String, dynamic>> _getCultoData(String cultoId) async {
    try {
      DocumentSnapshot cultoSnapshot =
          await _firestore.collection('Cultos').doc(cultoId).get();

      if (!cultoSnapshot.exists) {
        throw Exception('Culto não encontrado');
      }

      Map<String, dynamic> cultoData =
          cultoSnapshot.data() as Map<String, dynamic>;

      List<dynamic> playlist = cultoData['playlist'] ?? [];
      List<Map<String, dynamic>> loadedMusicas = [];
      List<Map<String, dynamic>> loadedMusicos = [];

      for (var item in playlist) {
        String musicDocumentId = item['music_document'];
        DocumentSnapshot musicSnapshot = await _firestore
            .collection('music_database')
            .doc(musicDocumentId)
            .get();

        if (musicSnapshot.exists) {
          loadedMusicas.add(musicSnapshot.data() as Map<String, dynamic>);
        } else {
          print('Música com ID $musicDocumentId não encontrada');
        }
      }

      cultoData['musicas'] = loadedMusicas;

      List<dynamic> musicosIds = cultoData['musicos'] ?? [];

      for (var item in musicosIds) {
        int userId = item['user_id'];
        QuerySnapshot userSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          loadedMusicos
              .add(userSnapshot.docs.first.data() as Map<String, dynamic>);
        } else {
          print('Usuário com ID $userId não encontrado');
        }
      }

      cultoData['musicos'] = loadedMusicos;

      return cultoData;
    } catch (e) {
      print('Erro ao buscar dados do culto: $e');
      throw e;
    }
  }

  Future<List<Map<String, String>>> fetchCultosAndMusic() async {
    // Passo 1: Buscar a referência do documento de culto usando o widget.id
    var cultosSnapshot = await FirebaseFirestore.instance
        .collection('Cultos')
        .doc(widget.id) // Usando o widget.id para buscar o documento específico
        .get();

    // Verificar se o documento existe
    if (!cultosSnapshot.exists) {
      return []; // Retorna uma lista vazia caso o culto não exista
    }

    // Passo 2: Buscar a playlist dentro do documento de culto
    var playlist = cultosSnapshot['playlist']
        as List; // Supondo que o campo 'playlist' seja uma lista

    List<Map<String, String>> musicDataList = [];

    // Passo 3: Iterar sobre os itens da playlist
    for (var item in playlist) {
      // Cada item é um mapa, então pegamos a chave 'music_document'
      var musicDocumentId = item['music_document'];
      var tone = item['key'];

      // Passo 4: Buscar os dados da música na collection 'music_database'
      var musicSnapshot = await FirebaseFirestore.instance
          .collection('music_database')
          .doc(musicDocumentId)
          .get();

      if (musicSnapshot.exists) {
        var musicData = musicSnapshot.data();
        String musicName = musicData?['Music'] ?? 'Unknown Music';
        String musicAuthor = musicData?['Author'] ?? 'Unknown Author';
        String musicBpm = musicData?['bpm'] ?? 'Unknown BPM';
        String key = item['key'] ?? 'Unknown key';

        // Passo 5: Buscar o campo 'content' relacionado na coleção 'songs'
        var songsQuerySnapshot = await FirebaseFirestore.instance
            .collection('songs')
            .where('SongId', isEqualTo: musicDocumentId)
            .get();

        String content = 'Content not found';
        String songDocumentId = 'Document ID not found';

        if (songsQuerySnapshot.docs.isNotEmpty) {
          var firstDoc = songsQuerySnapshot.docs.first;
          content = firstDoc['content'] ?? 'No content';
          songDocumentId = firstDoc.id; // ID do documento
        }

        // Adicionar os dados da música à lista
        musicDataList.add({
          'author': musicAuthor,
          'music': musicName,
          'id': musicDocumentId,
          'bpm': musicBpm,
          'content': content,
          'songDocumentId': songDocumentId, // Adicionando o ID do documento
          'tone': key, // Adicionando o ID do documento
        });
        print(key);
        print(songDocumentId);
      }
    }

    return musicDataList;
  }

  Widget _buildContent() {
// Função para mostrar os botões flutuantes

    switch (selectedMenu) {
      case 'Musicas':
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                      future: fetchCultosAndMusic(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Erro ao carregar os dados.'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                              child: Text('Nenhuma música encontrada.'));
                        }

                        var musicData = snapshot.data!;

                        return ListView.builder(
                          itemCount: musicData.length,
                          itemBuilder: (context, index) {
                            var music = musicData[index];
                            bool isExpanded = false;

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: isExpanded
                                            ? const Color.fromARGB(67, 0, 0, 0)
                                            : Colors.grey.shade300,
                                        width: isExpanded ? 1.0 : 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        if (isExpanded)
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                                    255, 0, 0, 0)
                                                .withOpacity(0.2),
                                            blurRadius: 8.0,
                                            spreadRadius: 1.0,
                                            offset: Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors
                                            .transparent, // Remove a linha entre o título e os filhos
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ExpansionTile(
                                          onExpansionChanged: (expanded) {
                                            setState(() {
                                              isExpanded = expanded;
                                            });
                                          },
                                          tilePadding: EdgeInsets
                                              .zero, // Remove o padding do título
                                          childrenPadding: EdgeInsets
                                              .zero, // Remove o padding dos filhos
                                          leading: Text(
                                            music['tone'] ?? "Sem Tom",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: const Color.fromARGB(
                                                  91, 0, 0, 0),
                                            ),
                                          ),
                                          title: Text(
                                            music['music'] ??
                                                'Música não disponível',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${music['author'] ?? 'Autor desconhecido'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VerLetraUser(
                                                              documentId:
                                                                  music['id'] ??
                                                                      '',
                                                              isAdmin: false,
                                                            ),
                                                          ),
                                                        )
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Colors
                                                                    .black),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical: 4),
                                                          child: Text(
                                                            "Ver Letra",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VerCifraUserNewUI(
                                                              documentId:
                                                                  music['id'] ??
                                                                      '',
                                                              tone: music[
                                                                      'tone'] ??
                                                                  '',
                                                              isAdmin: false,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Colors
                                                                    .black),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical: 4),
                                                          child: Text(
                                                            "Ver Cifra",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        openMetronome(
                                                            context,
                                                            int.parse(
                                                                music['bpm']!));
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                    color: Colors
                                                                        .black),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0,
                                                                      vertical:
                                                                          4),
                                                              child: Text(
                                                                music['bpm']!,
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }),
                ),
              ],
            ), // Botões flutuantes
          ],
        );
      case 'Teams':
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getEscalados(widget.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Nenhum escalado encontrado.'));
            }

            var escalados = snapshot.data!;

            return ListView.builder(
              itemCount: escalados.length,
              itemBuilder: (context, index) {
                var escalado = escalados[index];
                bool isExpanded = false;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors
                                .transparent, // Remove a linha entre o título e os filhos
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      clipBehavior: Clip
                                          .hardEdge, // Recorta o conteúdo do Container no formato definido
                                      child: Image.network(
                                        escalado['avatar'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      escalado['nome'] ?? 'Nome não disponível',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xffebf4fe),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 2),
                                    child: Text(
                                      '${escalado['instrument'] ?? 'Instrumento não definido'}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );

      case 'Ensaio':
        return Column(
          children: [
            Text('Ensaio Selecionado:'),
            ListTile(
              title: Text('Ensaio 1'),
            ),
            ListTile(
              title: Text('Ensaio 2'),
            ),
            ListTile(
              title: Text('Ensaio 3'),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Future<List<Map<String, dynamic>>> _getEscalados(String idCulto) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: idCulto)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> escaladosData = querySnapshot.docs.map((doc) {
        return {
          'idUser': doc['idUser'].toString(),
          'instrument': doc['Instrument'] ?? 'Instrumento não informado',
        };
      }).toList();

      List<Map<String, dynamic>> escalados = [];

      for (var escaladoData in escaladosData) {
        final userId = escaladoData['idUser'];
        final instrument = escaladoData['instrument'];

        final musicoDoc = await FirebaseFirestore.instance
            .collection('musicos')
            .where('user_id', isEqualTo: int.parse(userId))
            .get();

        if (musicoDoc.docs.isNotEmpty) {
          final musico = musicoDoc.docs.first.data();
          escalados.add({
            'nome': musico['name'] ?? 'Nome não disponível',
            'avatar': musico['photoUrl'] ?? 'photoUrl não disponível',
            'instrument': instrument,
          });
        } else {
          escalados.add({
            'nome': 'Músico não encontrado',
            'instrument': instrument,
          });
        }
      }

      return escalados;
    } catch (e) {
      print('Erro ao buscar escalados: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // final List<DocumentSnapshot> documentsAll = widget.documents;
    // final List<List<Map<String, dynamic>>> musicsAll = widget.musics;

    //  print(documentsAll[currentIndex].id);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: Text(
          "Detalhes",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [],
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Distribui o espaço entre os elementos
                    children: [
                      // O Expanded empurra o conteúdo restante para ocupar o espaço disponível

                      // Centraliza o texto
                      Column(
                        children: [
                          Row(
                            children: [],
                          ),
                        ],
                      ),
                      // O Spacer vai empurrar o próximo Expanded para o extremo direito
                    ],
                  ),
                ),
                /*
                */
                /*
                Text(
                  "Lagoinha Faro",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  documentsAll[currentIndex]['nome'] ?? 'Nome desconhecido',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  documentsAll[currentIndex]['date'] != null
                      ? DateFormat('dd/MM/yyyy').format(
                          (documentsAll[currentIndex]['date'] as Timestamp)
                              .toDate())
                      : 'Data desconhecida',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),*/
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Container(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton('Musicas'),
                    _buildMenuButton('Teams'),
                    _buildMenuButton('Notes'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String menu) {
    bool isSelected = selectedMenu == menu;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMenu = menu;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 160,
              height: 40,
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                border: Border.all(width: isSelected ? 1.00 : 0),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Center(
                child: Text(
                  menu,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  String avatarUrl;

  ProfileAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == "") {
      avatarUrl =
          "https://icons.veryicon.com/png/o/miscellaneous/standard/avatar-15.png";
    }
    return CircleAvatar(
      radius: 25, // Ajuste o tamanho conforme necessário
      backgroundColor: Colors.grey[200], // Cor de fundo do círculo
      backgroundImage: NetworkImage(avatarUrl),
      child: avatarUrl.isEmpty
          ? CircularProgressIndicator() // Exibe o indicador de carregamento se a URL estiver vazia
          : null,
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
