import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

/// The root widget.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Video Sessions',
      debugShowCheckedModeBanner: false,
      home: VideoSessionApp(),
    );
  }
}

/// This widget uses a bottom navigation bar to toggle between
/// the submission and play (rating) flows.
class VideoSessionApp extends StatefulWidget {
  @override
  _VideoSessionAppState createState() => _VideoSessionAppState();
}

class _VideoSessionAppState extends State<VideoSessionApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instagram Video Sessions")),
      body: _currentIndex == 0 ? SubmitVideoTab() : PlayVideoTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: "Submit"),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: "Play"),
        ],
      ),
    );
  }
}

/// ------------------------------
/// SUBMISSION PAGE
/// ------------------------------

class SubmitVideoTab extends StatefulWidget {
  @override
  _SubmitVideoTabState createState() => _SubmitVideoTabState();
}

class _SubmitVideoTabState extends State<SubmitVideoTab> {
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _submittedByController = TextEditingController();
  final TextEditingController _videoTitleController = TextEditingController();

  void _saveVideo() async {
    String session = _sessionController.text.trim();
    String url = _urlController.text.trim();
    String submittedBy = _submittedByController.text.trim();
    String videoTitle = _videoTitleController.text.trim();

    if (session.isEmpty ||
        url.isEmpty ||
        submittedBy.isEmpty ||
        videoTitle.isEmpty) return;

    // Package the video data into a JSON string.
    Map<String, String> videoData = {
      'url': url,
      'submittedBy': submittedBy,
      'videoTitle': videoTitle,
    };
    String videoJson = jsonEncode(videoData);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> videos = prefs.getStringList(session) ?? [];
    videos.add(videoJson);
    await prefs.setStringList(session, videos);

    // Clear the fields.
    _sessionController.clear();
    _urlController.clear();
    _submittedByController.clear();
    _videoTitleController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Video saved to session $session")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _sessionController,
            decoration: const InputDecoration(labelText: "Session Number"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _submittedByController,
            decoration: const InputDecoration(labelText: "Submitted By"),
          ),
          TextField(
            controller: _videoTitleController,
            decoration: const InputDecoration(labelText: "Video Title"),
          ),
          TextField(
            controller: _urlController,
            decoration:
                const InputDecoration(labelText: "Instagram Reel URL"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveVideo,
            child: const Text("Save Video"),
          ),
        ],
      ),
    );
  }
}

/// A simple model class for a video item.
class VideoItem {
  final String url;
  final String submittedBy;
  final String videoTitle;

  VideoItem({
    required this.url,
    required this.submittedBy,
    required this.videoTitle,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      url: json['url'] as String,
      submittedBy: json['submittedBy'] as String,
      videoTitle: json['videoTitle'] as String,
    );
  }
}

/// ------------------------------
/// PLAY PAGE – SESSION SEARCH
/// ------------------------------

class PlayVideoTab extends StatefulWidget {
  @override
  _PlayVideoTabState createState() => _PlayVideoTabState();
}

class _PlayVideoTabState extends State<PlayVideoTab> {
  final TextEditingController _sessionController = TextEditingController();
  List<String> _videoJsonList = [];
  String? _currentSession;

  void _loadVideos() async {
    String session = _sessionController.text.trim();
    if (session.isEmpty) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? videos = prefs.getStringList(session);
    setState(() {
      _videoJsonList = videos ?? [];
      _currentSession = session;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert the JSON strings into VideoItem objects.
    List<VideoItem> videoItems = _videoJsonList.map((jsonStr) {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return VideoItem.fromJson(data);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _sessionController,
            decoration:
                const InputDecoration(labelText: "Enter Session Number"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadVideos,
            child: const Text("Load Session"),
          ),
          const SizedBox(height: 20),
          if (videoItems.isNotEmpty && _currentSession != null)
            // Session overview button that shows the session number
            // and a brief list of video titles.
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RatingScreen(
                      session: _currentSession!,
                      videoItems: videoItems,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Text("Session $_currentSession"),
                  const SizedBox(height: 5),
                  Text(
                    "Videos: ${videoItems.map((v) => v.videoTitle).join(', ')}",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_currentSession != null)
            const Text("No videos found for this session."),
        ],
      ),
    );
  }
}

/// ------------------------------
/// RATING SCREEN
/// ------------------------------

/// A model class to hold a video along with its rating.
class RatedVideo {
  final VideoItem video;
  final int rating;
  RatedVideo({required this.video, required this.rating});
}

class RatingScreen extends StatefulWidget {
  final String session;
  final List<VideoItem> videoItems;

  RatingScreen({required this.session, required this.videoItems});

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int currentIndex = 0;
  double currentRating = 5.0;
  List<RatedVideo> ratedVideos = [];

  /// Submits the current rating and advances to the next video.
  void _submitRating() {
    RatedVideo rv = RatedVideo(
      video: widget.videoItems[currentIndex],
      rating: currentRating.toInt(),
    );
    ratedVideos.add(rv);
    if (currentIndex < widget.videoItems.length - 1) {
      setState(() {
        currentIndex++;
        currentRating = 5.0;
      });
    } else {
      // All videos have been rated; navigate to the leaderboard.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LeaderboardScreen(
            session: widget.session,
            ratedVideos: ratedVideos,
          ),
        ),
      );
    }
  }

  /// Launches the video URL using the url_launcher package.
  Future<void> _launchURL(String url, BuildContext context) async {
    // Ensure the URL has a scheme; if not, assume https.
    final String fixedUrl = url.startsWith('http') ? url : 'https://$url';
    final Uri uri = Uri.parse(fixedUrl);
    try {
      bool launched = false;
      if (kIsWeb) {
        // On web, launch without specifying a mode.
        launched = await launchUrl(uri);
      } else {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $fixedUrl')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    VideoItem currentVideo = widget.videoItems[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Rate Videos - Session ${widget.session}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display only the video title.
            Text(
              currentVideo.videoTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Display the clickable video URL.
            InkWell(
              onTap: () => _launchURL(currentVideo.url, context),
              child: Text(
                currentVideo.url,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text("Rating: ${currentRating.toInt()}",
                style: const TextStyle(fontSize: 18)),
            Slider(
              value: currentRating,
              min: 1,
              max: 10,
              divisions: 9,
              label: currentRating.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  currentRating = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRating,
              child: const Text("Submit Rating"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// LEADERBOARD SCREEN
/// ------------------------------

class LeaderboardScreen extends StatelessWidget {
  final String session;
  final List<RatedVideo> ratedVideos;

  LeaderboardScreen({required this.session, required this.ratedVideos});

  @override
  Widget build(BuildContext context) {
    // Sort the rated videos by rating in descending order.
    List<RatedVideo> sortedVideos = List.from(ratedVideos)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Scaffold(
      appBar: AppBar(title: Text("Leaderboard - Session $session")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sortedVideos.length,
          itemBuilder: (context, index) {
            RatedVideo rv = sortedVideos[index];
            return Card(
              child: ListTile(
                leading: Text("${index + 1}"),
                title: Text(rv.video.videoTitle),
                subtitle: Text("Submitted by: ${rv.video.submittedBy}"),
                trailing: Text("Rating: ${rv.rating}"),
              ),
            );
          },
        ),
      ),
    );
  }
}
