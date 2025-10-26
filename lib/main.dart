import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/item_listings_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/item_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/filter_search_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/rating_review_screen.dart';
import 'screens/transaction_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase depending on platform
  await Firebase.initializeApp(
    options: kIsWeb
        ? DefaultFirebaseOptions.web
        : DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Swap & Freecycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        primarySwatch: Colors.green, 
        
        primaryColor: Colors.green.shade700,
        
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
          secondary: Colors.orange, 
        ),

        scaffoldBackgroundColor: Colors.grey.shade50, 
        appBarTheme: AppBarTheme(
          color: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 1, 
        ),
        
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade500,
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // Initial screen: Login
      home: LoginScreen(),

      // Named routes
      routes: {
        '/item_listings': (context) => ItemListingsScreen(),
        '/add_item': (context) => AddItemScreen(),
        '/profile': (context) => ProfileScreen(),
        '/filter_search': (context) => FilterSearchScreen(),
        '/wishlist': (context) => WishlistScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/rating_review': (context) => RatingReviewScreen(),
        '/transaction_history': (context) => TransactionHistoryScreen(),
      },
    );
  }
}