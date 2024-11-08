import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class RecipeService {
  final String apiKey = '8ab45e7a4ae94cb984389ce58b8bc3eb';

  Future<List<Map<String, dynamic>>> fetchRecipesByIds(List<int> recipeIds) async {
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/informationBulk?ids=${recipeIds.join(",")}&apiKey=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> recipes = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      return recipes;
    } else {
      throw Exception('Failed to load recipes');
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _favorites = [];
  List<Map<String, dynamic>> _favoriteRecipes = [];

  void _toggleFavorite(Map<String, dynamic> recipe) {
    setState(() {
      if (_favorites.contains(recipe['title'])) {
        _favorites.remove(recipe['title']);
        _favoriteRecipes.removeWhere((favRecipe) => favRecipe['title'] == recipe['title']);
      } else {
        _favorites.add(recipe['title']);
        _favoriteRecipes.add(recipe);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zetna Fi de2e2na',
          style: GoogleFonts.dancingScript(
            fontSize: 36,
            color: Color(0xffFF1A75),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    favorites: _favoriteRecipes,
                    onFavoriteToggle: _toggleFavorite,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: HomeScreenBody(
        favorites: _favorites,
        onFavoriteToggle: _toggleFavorite,
      ),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  final List<String> favorites;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  HomeScreenBody({required this.favorites, required this.onFavoriteToggle});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  late Future<List<Map<String, dynamic>>> _recipesFuture;
  List<Map<String, dynamic>> _allRecipes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final recipeIds = [715538, 716429, 715495, 715497, 644387, 715421, 715594, 716408, 715540, 716381];
    _recipesFuture = RecipeService().fetchRecipesByIds(recipeIds);
    _loadRecipes();
  }

  void _loadRecipes() async {
    try {
      _allRecipes = await _recipesFuture;
      setState(() {});
    } catch (e) {
      print("Error loading recipes: $e");
    }
  }

  List<Map<String, dynamic>> _filteredRecipes() {
    return _allRecipes.where((recipe) {
      final title = recipe['title']?.toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for recipes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _recipesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error loading recipes"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No recipes found"));
              } else {
                final recipes = _filteredRecipes();
                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      isFavorited: widget.favorites.contains(recipe['title']),
                      onFavoriteToggle: widget.onFavoriteToggle,
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool isFavorited;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  RecipeCard({
    required this.recipe,
    required this.isFavorited,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final recipeTitle = recipe['title'];
    final recipeDescription = recipe['summary'] ?? "No description available.";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                title: recipeTitle,
                description: recipeDescription.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
              ),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const Icon(Icons.fastfood),
          title: Text(recipeTitle),
          subtitle: const Text("Tap for more details"),
          trailing: IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : null,
            ),
            onPressed: () {
              onFavoriteToggle(recipe);
            },
          ),
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final String title;
  final String description;

  RecipeDetailScreen({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.dancingScript(
            fontSize: 28,
            color: Color(0xffFF1A75),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          description,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final Function(Map<String, dynamic>) onFavoriteToggle;

  FavoritesScreen({required this.favorites, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: GoogleFonts.dancingScript(
            fontSize: 28,
            color: Color(0xffFF1A75),
          ),
        ),
      ),
      body: favorites.isEmpty
          ? Center(child: Text('No favorites yet!'))
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final recipe = favorites[index];
          return RecipeCard(
            recipe: recipe,
            isFavorited: true,
            onFavoriteToggle: onFavoriteToggle,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactUsScreen(),
            ),
          );
        },
        child: Icon(Icons.contact_mail),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: GoogleFonts.dancingScript(
            fontSize: 28,
            color: Color(0xffFF1A75),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Phone Number: +123 456 7890',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Email: contact@zetna.com',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
