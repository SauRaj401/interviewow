import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:interviewow/pageB.dart';

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PageA(),
    );
  }
}

class PageA extends StatefulWidget {
  const PageA({Key? key}) : super(key: key);

  @override
  _PageAState createState() => _PageAState();
}

class _PageAState extends State<PageA> {
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      List<Photo> photos = [];
      for (var data in responseData) {
        final imageUrlResponse = await http.get(Uri.parse(
            'https://jsonplaceholder.typicode.com/photos/${data['id']}'));
        if (imageUrlResponse.statusCode == 200) {
          final photoData = jsonDecode(imageUrlResponse.body);
          photos.add(Photo.fromJson(photoData));
        } else {
          throw Exception('Failed to load image URL');
        }
      }

      setState(() {
        posts = responseData.map((data) {
          final photo = photos.firstWhere((photo) => photo.id == data['id']);
          return Post.fromJson(data, photo.url);
        }).toList();
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page A'),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(posts[index].title),
            leading: FutureBuilder(
              future: _loadImage(posts[index].imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Icon(
                      Icons.error); // Show error icon if image loading fails
                } else {
                  return Image.memory(snapshot.data!
                      as Uint8List); // Assuming the image data is bytes
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PageB(postId: posts[index].id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<Uint8List?> _loadImage(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  } catch (e) {
    throw Exception('Error loading image: $e');
  }
}

class Post {
  final int id;
  final String title;
  final String imageUrl;

  Post({required this.id, required this.title, required this.imageUrl});

  factory Post.fromJson(Map<String, dynamic> json, String imageUrl) {
    return Post(
      id: json['id'],
      title: json['title'],
      imageUrl: imageUrl,
    );
  }
}

class Photo {
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  Photo({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}
