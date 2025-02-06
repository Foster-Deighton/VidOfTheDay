import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kIsWeb if needed
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart'; // Correct import

// Global variable to store the current user's name.
String currentUserName = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Parse. Replace the placeholders with your Back4App credentials.
  await Parse().initialize(
    '3l5MJh12atq8OELEibxI3ajrbArckxUL50lvEy24',
    'https://parseapi.back4app.com',
    clientKey: 'Rc4IlAMlJEjrrrAHy7ZJsM4zcgi6EH7zXT1DDiCz',
    autoSendSessionId: true,
  );
  runApp(MyApp());
}

/// The root widget.
/// The home is set to LoginScreen so that the user must enter their name before using the app.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Video Sessions',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

/// ------------------------------
/// LOGIN SCREEN
/// ------------------------------

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _enterApp() {
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter your name."),
          backgroundColor: Color(0xFFC6AB90),
        ),
      );
      return;
    }
    // Save the name globally.
    currentUserName = name;
    // Optionally, you could persist this in SharedPreferences.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => VideoSessionApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)], // Deep space effect
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/buff.png', 
                height: 450, width: 450
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Who Is This??",
                  filled: true,
                  fillColor: Color(0xFF222222), // Darker tone for input
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFC6AB90)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5C39C)), // Softer beige
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enterApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE5C39C), // Slightly lighter beige
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded edges for a modern look
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text("Enter The Thunderdome", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




/// ------------------------------
/// MAIN APP: VIDEO SESSION APP
/// ------------------------------

class VideoSessionApp extends StatefulWidget {
  @override
  _VideoSessionAppState createState() => _VideoSessionAppState();
}

class _VideoSessionAppState extends State<VideoSessionApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vid Of The Day", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF0F0F0F), // Darker black for contrast
      ),
      body: _currentIndex == 0 ? SubmitVideoTab() : PlayVideoTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Color(0xFF1E1E1E), // Dark background for nav bar
        selectedItemColor: Color(0xFFC6AB90), // Beige for selected items
        unselectedItemColor: Colors.white70, // Lighter white for unselected items
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
  final TextEditingController _videoTitleController = TextEditingController();

  void _saveVideo() async {
    String session = _sessionController.text.trim();
    String videoTitle = _videoTitleController.text.trim();

    if (session.isEmpty || videoTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Session and video name are required."),
          backgroundColor: Color(0xFFC6AB90), // Theme color for alerts
        ),
      );
      return;
    }

    // Use the globally stored username.
    String submittedBy = currentUserName;

    // Create a ParseObject to save to Back4App (Videos table)
    var videoObject = ParseObject('Videos')
      ..set('session', session)  // Session number
      ..set('name', videoTitle)  // Video title (stored in "name" column)
      ..set('url', _urlController.text.trim())
      ..set('user', submittedBy); // User who submitted the video

    // Save the object to Back4App
    final response = await videoObject.save();

    if (response.success) {
      // Clear the fields after saving successfully.
      _sessionController.clear();
      _videoTitleController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Video '$videoTitle' saved to session $session."),
          backgroundColor: Color(0xFF0F0F0F), // Darker background
        ),
      );
    } else {
      print("Error saving video: \${response.error?.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save video. Try again."),
          backgroundColor: Color(0xFFC6AB90),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)], // Deep space effect
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/buff.png', // Ensure this matches your actual asset path
              height: 250, width: 250
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sessionController,
              decoration: InputDecoration(
                labelText: "Session Number",
                filled: true,
                fillColor: Color(0xFF222222), // Darker tone for input
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFC6AB90)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5C39C)),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _videoTitleController,
              decoration: InputDecoration(
                labelText: "Video Title",
                filled: true,
                fillColor: Color(0xFF222222),
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFC6AB90)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5C39C)),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "Instagram Reel URL",
                filled: true,
                fillColor: Color(0xFF222222),
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFC6AB90)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5C39C)),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE5C39C), // Slightly lighter beige
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded edges for a modern look
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text("Save Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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

  // ✅ Add this method to convert VideoItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'submittedBy': submittedBy,
      'videoTitle': videoTitle,
    };
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
    if (session.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a session number."),
          backgroundColor: Color(0xFFC6AB90),
        ),
      );
      return;
    }

    try {
      QueryBuilder<ParseObject> query = QueryBuilder<ParseObject>(ParseObject('Videos'))
        ..whereEqualTo('session', session);

      final response = await query.query();

      if (response.success && response.results != null) {
        List<VideoItem> fetchedVideos = response.results!.map((video) {
          return VideoItem(
            url: video.get<String>('url') ?? 'No URL',
            submittedBy: video.get<String>('user') ?? 'Unknown',
            videoTitle: video.get<String>('name') ?? 'Untitled Video',
          );
        }).toList();

        setState(() {
          _videoJsonList = fetchedVideos.map((v) => jsonEncode(v.toJson())).toList();
          _currentSession = session;
        });
      } else {
        print("No videos found OR issue with response: \${response.error?.message}");
        setState(() {
          _videoJsonList = [];
          _currentSession = session;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No videos found for session $session."),
            backgroundColor: Color(0xFFC6AB90),
          ),
        );
      }
    } catch (e) {
      print("Error loading videos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load videos. Please try again."),
          backgroundColor: Color(0xFFC6AB90),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<VideoItem> videoItems = _videoJsonList.map((jsonStr) {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return VideoItem.fromJson(data);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/buff.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sessionController,
              decoration: InputDecoration(
                labelText: "Enter Session Number",
                filled: true,
                fillColor: Color(0xFF222222),
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFC6AB90)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE5C39C)),
                ),
              ),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE5C39C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text("Load Session", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            if (videoItems.isNotEmpty && _currentSession != null)










              ElevatedButton(
  onPressed: () async {
    bool ratedAlready = false;
    List<String> ratedVideos = []; // To store videos rated by the user

    final QueryBuilder<ParseObject> pressedYet = 
        QueryBuilder<ParseObject>(ParseObject('ratings'))
        ..whereEqualTo('session', _currentSession);

    final ratedThing = await pressedYet.query();
    final List? results = ratedThing.results;

    print(results);

    // Check if user has already rated this session and collect rated videos
    for (final review in results ?? []) {
      if (review.get<String>('rated_by') == currentUserName) {
        ratedAlready = true;
        ratedVideos.add(review.get<String>('video_title') ?? 'Unknown Video'); // Adjust 'video_title' to match your field
      }
    }

    // If the user hasn't rated yet, allow them to rate
    if (!ratedAlready) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RatingScreen(
            session: _currentSession!,
            videoItems: videoItems,
          ),
        ),
      );
    } 
    // If the user has already rated, redirect to the leaderboard with ratedVideos
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeaderboardScreen(
            session: _currentSession!,
            ratedVideos: ratedVideos.map((title) => RatedVideo(video: VideoItem(url: '', submittedBy: '', videoTitle: title), rating: 0)).toList(),  // Convert to List<RatedVideo>
          ),
        ),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFC6AB90),
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Column(
    children: [
      Text(
        "Session $_currentSession",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 5),
      Text(
        "Videos: ${videoItems.map((v) => v.videoTitle).join(', ')}",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ],
  ),
)



            else if (_currentSession != null)
              const Text("No videos found for this session.", style: TextStyle(color: Colors.white)),
          ],
        ),
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

  Future<void> _submitRating() async {
    int ratingValue = currentRating.toInt();
    VideoItem currentVideo = widget.videoItems[currentIndex];

    var ratingObject = ParseObject('ratings')
      ..set('user', currentVideo.submittedBy)
      ..set('video', currentVideo.videoTitle)
      ..set('rated_by', currentUserName)
      ..set('rating', ratingValue)
      ..set('session', widget.session);

    final response = await ratingObject.save();

    if (response.success) {
      RatedVideo rv = RatedVideo(
        video: currentVideo,
        rating: ratingValue,
      );
      ratedVideos.add(rv);

      if (currentIndex < widget.videoItems.length - 1) {
        setState(() {
          currentIndex++;
          currentRating = 5.0;
        });
      } else {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save rating. Please try again.'),
          backgroundColor: Color(0xFFC6AB90),
        ),
      );
    }
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final String fixedUrl = url.startsWith('http') ? url : 'https://$url';
    final Uri uri = Uri.parse(fixedUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
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
      appBar: AppBar(
        title: Text(
          "Rate Videos - Session ${widget.session}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0F0F0F),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset(
                'assets/buff.png',
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                currentVideo.videoTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
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
              Text(
                "Rating: ${currentRating.toInt()}",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              Slider(
                value: currentRating,
                min: 1,
                max: 10,
                divisions: 9,
                label: currentRating.toInt().toString(),
                activeColor: Color(0xFFE5C39C),
                inactiveColor: Color(0xFF555555),
                onChanged: (value) {
                  setState(() {
                    currentRating = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE5C39C),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text(
                  "Submit Rating",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ------------------------------
/// LEADERBOARD SCREEN
/// ------------------------------

class LeaderboardScreen extends StatefulWidget {
  final String session;

  LeaderboardScreen({required this.session, required List<RatedVideo> ratedVideos});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    try {
      // Query all unique videos for the session
      QueryBuilder<ParseObject> videoQuery = QueryBuilder<ParseObject>(ParseObject('Videos'))
        ..whereEqualTo('session', widget.session);

      final videoResponse = await videoQuery.query();

      if (videoResponse.success && videoResponse.results != null) {
        List<Map<String, dynamic>> tempLeaderboard = [];

        for (var video in videoResponse.results!) {
          String videoTitle = video.get<String>('name') ?? 'Untitled Video';
          String submittedBy = video.get<String>('user') ?? 'Unknown';
          String videoUrl = video.get<String>('url') ?? 'No URL';

          // Fetch all ratings for this video in the session
          QueryBuilder<ParseObject> ratingQuery = QueryBuilder<ParseObject>(ParseObject('ratings'))
            ..whereEqualTo('video', videoTitle)
            ..whereEqualTo('session', widget.session);

          final ratingResponse = await ratingQuery.query();

          List<int> ratings = [];
          if (ratingResponse.success && ratingResponse.results != null) {
            for (var ratingObj in ratingResponse.results!) {
              ratings.add(ratingObj.get<int>('rating'));
            }
          }

          // Calculate the average rating
          double averageRating = ratings.isNotEmpty
              ? ratings.reduce((a, b) => a + b) / ratings.length
              : 0.0; // Default to 0 if no ratings

          tempLeaderboard.add({
            'videoTitle': videoTitle,
            'submittedBy': submittedBy,
            'averageRating': averageRating,
            'videoUrl': videoUrl,
          });
        }

        // Sort videos by highest average rating
        tempLeaderboard.sort((a, b) => b['averageRating'].compareTo(a['averageRating']));

        setState(() {
          leaderboardData = tempLeaderboard;
        });
      } else {
        print("No videos found or issue with response: ${videoResponse.error?.message}");
      }
    } catch (e) {
      print("Error loading leaderboard data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Color(0xFF0F0F0F), // Deep black for an immersive dark theme
  appBar: AppBar(
    title: Text(
      "Leaderboard - Session ${widget.session}",
      style: TextStyle(color: Color(0xFFE5C39C), fontWeight: FontWeight.bold), // Warm beige for contrast
    ),
    backgroundColor: Color(0xFF1A1A1A), // Slightly lighter black for better separation
    elevation: 4, // Subtle shadow to make it distinct
    shadowColor: Color(0xFF0A0A0A), // Darker shadow for depth
    iconTheme: IconThemeData(color: Color(0xFFE5C39C)), // Make the back button beige for visibility
  ),
  body: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)], // Subtle gradient effect
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: leaderboardData.isEmpty
        ? Center(child: CircularProgressIndicator(color: Color(0xFFE5C39C))) // Beige loading indicator
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                var video = leaderboardData[index];

                return Card(
                  color: Color(0xFF222222), // Dark gray card to stand out slightly from background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Smooth edges
                  ),
                  child: ListTile(
                    leading: Text(
                      "#${index + 1}",
                      style: TextStyle(color: Color(0xFFE5C39C), fontWeight: FontWeight.bold), // Strong contrast
                    ),
                    title: Text(
                      video['videoTitle'],
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Submitted by: ${video['submittedBy']}",
                      style: TextStyle(color: Color(0xFFC6AB90), fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Avg Rating: ${video['averageRating'].toStringAsFixed(1)}",
                          style: TextStyle(color: Color(0xFFE5C39C), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, color: Color(0xFFE5C39C), size: 18), // Visible arrow
                      ],
                    ),
                    onTap: () => _launchURL(video['videoUrl'], context),
                  ),
                );
              },
            ),
          ),
  ),
);


  }

  // Open video URL in browser
  Future<void> _launchURL(String url, BuildContext context) async {
    if (url.isEmpty || url == 'No URL') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No URL available for this video')),
      );
      return;
    }

    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }
}
