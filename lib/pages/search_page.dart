import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:logging/logging.dart';

final log = Logger('SearchPageLogs');

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentUsers = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
    
    // Set up listener for search input
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // Load recent users to show initially - using real Firestore data
  Future<void> _loadRecentUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Query for most recently created users with isPublic=true
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      final List<Map<String, dynamic>> users = [];
      
      // Process the query results
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Only include if it has required fields
        if (data.containsKey('displayName') && data.containsKey('beavertag')) {
          users.add({
            'uid': doc.id,
            'displayName': data['displayName'] ?? 'User',
            'beavertag': data['beavertag'] ?? '',
            'photoURL': data['photoURL'],
            'isPublic': data['isPublic'] ?? false,
          });
        }
      }
      
      setState(() {
        _recentUsers = users;
        _isLoading = false;
      });
      
      log.info('Loaded ${users.length} recent public users');
    } catch (e) {
      log.severe('Error loading recent users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Handle search input changes with debounce
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }
  
  // Perform the actual search using Firestore
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final String normalizedQuery = query.toLowerCase().trim();
      String beavertagQuery = normalizedQuery;
      
      // Remove '$' if user included it in beavertag search
      if (beavertagQuery.startsWith('\$')) {
        beavertagQuery = beavertagQuery.substring(1);
      }
      
      // Query users by display name
      final QuerySnapshot nameResults = await FirebaseFirestore.instance
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .where('displayName_lower', isGreaterThanOrEqualTo: normalizedQuery)
          .where('displayName_lower', isLessThanOrEqualTo: normalizedQuery + '\uf8ff')
          .limit(20)
          .get();
      
      // Query users by beavertag
      final QuerySnapshot beavertagResults = await FirebaseFirestore.instance
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .where('beavertag', isGreaterThanOrEqualTo: beavertagQuery)
          .where('beavertag', isLessThanOrEqualTo: beavertagQuery + '\uf8ff')
          .limit(20)
          .get();
      
      // Combine and deduplicate results
      final Map<String, Map<String, dynamic>> uniqueResults = {};
      
      // Process name results
      for (var doc in nameResults.docs) {
        final data = doc.data() as Map<String, dynamic>;
        uniqueResults[doc.id] = {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'User',
          'beavertag': data['beavertag'] ?? '',
          'photoURL': data['photoURL'],
          'isPublic': data['isPublic'] ?? false,
        };
      }
      
      // Process beavertag results
      for (var doc in beavertagResults.docs) {
        final data = doc.data() as Map<String, dynamic>;
        uniqueResults[doc.id] = {
          'uid': doc.id,
          'displayName': data['displayName'] ?? 'User',
          'beavertag': data['beavertag'] ?? '',
          'photoURL': data['photoURL'],
          'isPublic': data['isPublic'] ?? false,
        };
      }
      
      setState(() {
        _searchResults = uniqueResults.values.toList();
        _isLoading = false;
      });
      
      log.info('Found ${_searchResults.length} users matching "$query"');
    } catch (e) {
      log.severe('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.background,
      child: Column(
        children: [
          // Search Bar - CashApp style with pill shape
          Container(
            margin: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(28),
            ),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Name, \$Beavertag, email, phone',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            
          // Section label - CashApp uses subtle section headers
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    _hasSearched ? 'SEARCH RESULTS' : 'PEOPLE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
          // Results or suggested users
          Expanded(
            child: _hasSearched
                ? _buildSearchResults()
                : _buildSuggestedUsers(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Try searching for a name, \$Beavertag, email, or phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.transparent,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserListTile(user);
      },
    );
  }
  
  Widget _buildSuggestedUsers() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_recentUsers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 56,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'Search for people',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Find friends by name, \$Beavertag, email, or phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _recentUsers.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.transparent, 
        height: 1,
      ),
      itemBuilder: (context, index) {
        final user = _recentUsers[index];
        return _buildUserListTile(user);
      },
    );
  }
  
  Widget _buildUserListTile(Map<String, dynamic> user) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isSelf = currentUser?.uid == user['uid'];
    
    // CashApp's list items are simple with subtle hover effects
    return InkWell(
      onTap: () {
        if (!isSelf) {
          _navigateToPayPage(user);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar - CashApp uses slightly larger avatars
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: user['photoURL'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        user['photoURL'],
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          log.warning('Could not load profile image: $error');
                          return Center(
                            child: Text(
                              _getInitial(user['displayName']),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitial(user['displayName']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 16),
            // User info - CashApp shows display name and Beavertag stacked
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['displayName'] ?? 'User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onBackground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '\$${user['beavertag']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Pay button - CashApp uses a simple pay icon
            if (!isSelf)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withOpacity(0.4),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.attach_money,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _navigateToPayPage(user);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper to get the initial letter for avatar fallback
  String _getInitial(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return '?';
    }
    return displayName[0].toUpperCase();
  }
  
  // Navigate to the payment page with selected user
  void _navigateToPayPage(Map<String, dynamic> user) {
    log.info('Navigating to pay page for user: ${user['displayName']} (${user['uid']})');
    // Navigate to payment page with selected user
    // In a real implementation, you would use Navigator to go to the payment screen
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => PaymentPage(recipient: user),
    //   ),
    // );
  }
}