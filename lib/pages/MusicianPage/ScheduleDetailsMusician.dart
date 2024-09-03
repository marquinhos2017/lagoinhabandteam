import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerCifraUser.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerLetra.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart'; // Pacote para reproduzir som (adicionar no pubspec.yaml)

class AudioPlayerBottomSheet extends StatefulWidget {
  final String audioUrl;
  final String music;
  final String author;
  final String lyrics;
  final String documentId; // Use documentId to fetch lyrics from Firestore

  AudioPlayerBottomSheet({
    required this.audioUrl,
    required this.music,
    required this.author,
    required this.lyrics,
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
                          Text(
                            widget.music,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            widget.author,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.white),
                          ),
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
          audioUrl: audioUrl,
          music: musica,
          author: author,
          lyrics: lyrics,
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
  final List<DocumentSnapshot> documents;
  final int currentIndex;
  final List<List<Map<String, dynamic>>> musics;

  const ScheduleDetailsMusician({
    required this.id,
    required this.documents,
    required this.currentIndex,
    required this.musics,
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
    currentIndex = widget.currentIndex;
    _loadInitialData(); // Carrega os dados iniciais ao iniciar
  }

  Future<void> _loadInitialData([String? cultoId]) async {
    try {
      Map<String, dynamic> fetchedCultoData =
          await _getCultoData(cultoId ?? widget.id);

      // Buscar documentos na coleção 'user_culto_instrument'
      List<Map<String, dynamic>> userCultoInstruments =
          await _getUserCultoInstruments(widget.documents[currentIndex].id);

      setState(() {
        cultoData = fetchedCultoData;
        musicos = List<Map<String, dynamic>>.from(cultoData?['musicos'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados iniciais: $e');
      setState(() {
        isLoading = false;
      });
    }
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
          print(userData['name']);
        } else {
          data['name'] = 'Nome não encontrado';
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

  void _navigateToDocument(int index) async {
    if (index < 0 || index >= widget.documents.length)
      return; // Check index bounds

    setState(() {
      isLoading = true;
      currentIndex = index;
    });

    await _loadInitialData(widget.documents[currentIndex].id);
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case 'Musicas':
        List<Map<String, dynamic>> musicasAtuais = widget.musics[currentIndex];

        return Container(
          color: Colors.white,
          child: ListView(
            children: musicasAtuais
                .map((musica) => Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 24.0, right: 24, top: 8),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          maintainState: false,
                          iconColor: Colors.black,
                          shape: Border.all(color: Colors.black),
                          dense: false,
                          title: Row(
                            children: [
                              Text("1"),
                              SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    musica['Music'] ?? 'Título desconhecido',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Text(
                                    musica['Author'] ?? 'Autor desconhecido',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        'Tom: ${musica['key'] ?? 'Desconhecido'}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      openMetronome(
                                          context, int.parse(musica['bpm']));
                                    },
                                    child: Text(
                                      'BPM: ${musica['bpm'] ?? ''}',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 10),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Link da Música'),
                                                  content: Text(musica[
                                                          'link'] ??
                                                      'Link não disponível'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('Fechar'),
                                                    ),
                                                    if (musica['link'] !=
                                                            null &&
                                                        musica['link']
                                                            .isNotEmpty)
                                                      TextButton(
                                                        onPressed: () {
                                                          void _openLink(
                                                              String
                                                                  url) async {
                                                            final Uri uri =
                                                                Uri.parse(url);
                                                            if (await canLaunchUrl(
                                                                uri)) {
                                                              await launchUrl(
                                                                  uri,
                                                                  mode: LaunchMode
                                                                      .externalApplication);
                                                            } else {
                                                              throw 'Não foi possível abrir o URL: $url';
                                                            }
                                                          }

                                                          _openLink(
                                                              musica['link']);
                                                        },
                                                        child: Text(
                                                            'Abrir no Navegador'),
                                                      ),
                                                  ],
                                                );
                                              },
                                            );

                                            print(musica['link']);
                                          },
                                          child: Icon(Icons.music_video)),
                                      SizedBox(
                                        width: 12,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VerCifraUserNewUI(
                                                documentId:
                                                    musica['document_id'],
                                                isAdmin: false,
                                                tone: musica['key'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.library_music_rounded,
                                          color: Colors.black,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 12,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          showPlayerBlurBottomSheet(
                                              context,
                                              musica['link_audio'].toString(),
                                              musica['Music'],
                                              musica['Author'],
                                              musica['letra'],
                                              musica['id_musica']);
                                        },
                                        child: Icon(
                                          Icons.play_circle,
                                          color: Colors.black,
                                          size: 24,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Verletra(
                                                documentId:
                                                    musica['document_id'],
                                                isAdmin: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          // Adicione um Hero aqui se estiver fazendo animações com Hero
                                          tag:
                                              'song-hero-${musica['document_id']}', // Certifique-se de que a tag seja única
                                          child: Icon(
                                            Icons.lyrics,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        );
      case 'Teams':
        if (isLoading) {
          return Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getUserCultoInstruments(widget.documents[currentIndex].id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Erro ao carregar dados: ${snapshot.error}',
                      style: TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: Text('Nenhum dado disponível',
                      style: TextStyle(color: Colors.white)));
            }

            return Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: snapshot.data!
                    .map((item) => Container(
                          margin: EdgeInsets.all(12),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['name'].toString().toTitleCase() ??
                                      'Nome desconhecido',
                                  style: GoogleFonts.montserrat(
                                      textStyle:
                                          TextStyle(color: Colors.black)),
                                ),
                                if (item['Instrument'] == "Piano")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "Guitarra")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "Bateria")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "Violão")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.brown,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "Baixo")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "MD")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "Ministro")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "BV 1")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.cyan,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "BV 2")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item['Instrument'] == "BV 3")
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        ' ${item['Instrument'] ?? 'Desconhecido'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
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

  @override
  Widget build(BuildContext context) {
    final List<DocumentSnapshot> documentsAll = widget.documents;
    final List<List<Map<String, dynamic>>> musicsAll = widget.musics;
    final id = documentsAll[currentIndex].id;
    print(documentsAll[currentIndex].id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: Text(
          "Service Details",
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
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Distribui o espaço entre os elementos
                    children: [
                      // O Expanded empurra o conteúdo restante para ocupar o espaço disponível
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              icon: Icon(Icons.arrow_left, color: Colors.white),
                              onPressed: () {
                                if (currentIndex > 0) {
                                  _navigateToDocument(currentIndex - 1);
                                } else {
                                  print("Não há documento anterior.");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Centraliza o texto
                      Column(
                        children: [
                          Text(
                            documentsAll[currentIndex]['nome'] ??
                                'Nome desconhecido',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(
                                        (documentsAll[currentIndex]['date']
                                                as Timestamp)
                                            .toDate()) ??
                                    'Nome desconhecido',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(" - "),
                              Text(
                                documentsAll[currentIndex]['horario'] ??
                                    'Nome desconhecido',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // O Spacer vai empurrar o próximo Expanded para o extremo direito

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              icon:
                                  Icon(Icons.arrow_right, color: Colors.white),
                              onPressed: () {
                                if (currentIndex <
                                    widget.documents.length - 1) {
                                  _navigateToDocument(currentIndex + 1);
                                } else {
                                  print("Não há documento seguinte.");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
          SizedBox(height: 12),
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
