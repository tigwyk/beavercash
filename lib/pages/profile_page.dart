import 'dart:io';
import 'package:beavercash/services/db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

final log = Logger('ProfilePageLogs');

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService firestoreService = FirestoreService();
  bool _isUploading = false;
  bool _isEditing = false; // Track if we're in edit mode

  // Create a key to reference the form
  final GlobalKey<_UserInformationState> _userInfoKey = GlobalKey();

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
  
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _isUploading = true;
      });
      
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to change your profile picture')),
        );
        return;
      }
      
      // Upload to Firebase Storage
      final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
      
      final File imageFile = File(image.path);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Get the download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      // Update user profile
      await user.updatePhotoURL(downloadUrl);
      
      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': downloadUrl});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      log.severe('Error picking or uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    // If we're entering edit mode, tell the UserInformation widget to start editing
    if (_isEditing) {
      _userInfoKey.currentState?.startEditing();
    } else {
      // If we're exiting edit mode, tell the UserInformation widget to save changes
      _userInfoKey.currentState?.saveChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Add edit/save button in app bar for better UX
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Save changes' : 'Edit profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Stack(
                children: [
                  // Profile image with loading indicator when uploading
                  GestureDetector(
                    onTap: _isEditing ? _showImageSourceDialog : null, // Only enable tap when editing
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: currentUser?.photoURL != null && !_isUploading
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: _isUploading
                          ? CircularProgressIndicator()
                          : currentUser?.photoURL == null
                              ? Text(
                                  currentUser?.displayName?.isNotEmpty == true
                                      ? currentUser!.displayName![0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 48,
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                    ),
                  ),
                  // Edit button overlay - only show when in edit mode
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Pass the edit mode status to the UserInformation widget
              UserInformation(
                key: _userInfoKey,
                isEditing: _isEditing,
              ),
              
              SizedBox(height: 32),
              
              // Edit Profile button - mobile style action button
              ElevatedButton.icon(
                onPressed: _toggleEditMode,
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                label: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
                  foregroundColor: _isEditing ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: Size(200, 45),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Sign Out button
              ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Sign Out'),
                      content: Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Sign Out'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (shouldSignOut) {
                    await signOut();
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
                icon: Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: Size(200, 45),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Modified UserInformation class to support editing
class UserInformation extends StatefulWidget {
  final bool isEditing;
  
  const UserInformation({
    Key? key,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _UserInformationState createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Controllers for the text fields
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  // Add a boolean for tracking visibility setting
  bool _isProfilePublic = false;
  final _formKey = GlobalKey<FormState>();
  
  // Store the document data
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Called from parent to enter edit mode
  void startEditing() {
    if (_userData != null) {
      _displayNameController.text = _userData!['displayName'] ?? '';
      _phoneController.text = _userData!['phoneNumber'] ?? '';
      // Initialize visibility toggle from user data
      setState(() {
        _isProfilePublic = _userData!['isPublic'] ?? false;
      });
    }
  }
  
  // Called from parent to save changes
  Future<void> saveChanges() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Don't save if nothing changed (now including isPublic flag)
    if (_userData != null &&
        _userData!['displayName'] == _displayNameController.text &&
        _userData!['phoneNumber'] == _phoneController.text &&
        _userData!['isPublic'] == _isProfilePublic) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update Firestore with the additional isPublic field
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'displayName': _displayNameController.text,
        'phoneNumber': _phoneController.text,
        'isPublic': _isProfilePublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update Firebase Auth display name if it changed
      if (_userData!['displayName'] != _displayNameController.text) {
        await user!.updateDisplayName(_displayNameController.text);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      log.severe('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Return early if there's no logged in user
    if (user == null) {
      return const Text('No user logged in');
    }

    // Query only the specific document for the current user
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Check if the document exists
        if (!snapshot.hasData || !snapshot.data!.exists) {
          log.info('UID: ${user!.uid}');
          return const Text('User profile not found');
        }

        // Get the data from the document
        _userData = snapshot.data!.data() as Map<String, dynamic>;
        
        // Set controllers if in edit mode
        if (widget.isEditing && (_displayNameController.text.isEmpty || _phoneController.text.isEmpty)) {
          _displayNameController.text = _userData!['displayName'] ?? '';
          _phoneController.text = _userData!['phoneNumber'] ?? '';
        }

        return widget.isEditing
            ? _buildEditForm(context, _userData!)
            : _buildProfileInfo(context, _userData!);
      },
    );
  }
  
  // Build the read-only profile info view
  Widget _buildProfileInfo(BuildContext context, Map<String, dynamic> userData) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Beaver tag with visibility indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${userData['beavertag'] ?? 'No tag'}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: 8),
                // Show visibility icon
                Icon(
                  userData['isPublic'] == true ? Icons.public : Icons.public_off,
                  size: 16,
                  color: userData['isPublic'] == true 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Display name
            Text(
              userData['displayName'] ?? 'Name not set',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            
            // Email
            Text(
              userData['email'] ?? user!.email ?? 'Email not available',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
            ),
            
            // User information rows
            _buildInfoRow(Icons.phone, 'Phone', 
              userData['phoneNumber'] ?? 'Not provided',
            ),
            
            SizedBox(height: 12),
            
            _buildInfoRow(Icons.calendar_today, 'Member since', 
              _formatDate(userData['createdAt']),
            ),
            
            SizedBox(height: 12),
            
            // Profile visibility status
            _buildInfoRow(
              userData['isPublic'] == true ? Icons.public : Icons.public_off,
              'Profile visibility',
              userData['isPublic'] == true ? 'Public' : 'Private',
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a row with an icon and info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build the editable form for profile info
  Widget _buildEditForm(BuildContext context, Map<String, dynamic> userData) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Form(
      key: _formKey,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Non-editable beaver tag
              Center(
                child: Text(
                  '\$${userData['beavertag'] ?? 'No tag'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Display name field
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Non-editable email
              TextFormField(
                initialValue: userData['email'] ?? user!.email ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Phone number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Optional phone validation if needed
              ),
              SizedBox(height: 20),
              
              // Add the profile visibility toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Visibility',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Control who can find and pay you',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 12),
                    // The switch with labels
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _isProfilePublic,
                                onChanged: (value) {
                                  setState(() {
                                    _isProfilePublic = value!;
                                  });
                                },
                                activeColor: colorScheme.primary,
                              ),
                              Text(
                                'Public',
                                style: textTheme.bodyMedium,
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.public,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: false,
                                groupValue: _isProfilePublic,
                                onChanged: (value) {
                                  setState(() {
                                    _isProfilePublic = value!;
                                  });
                                },
                                activeColor: colorScheme.primary,
                              ),
                              Text(
                                'Private',
                                style: textTheme.bodyMedium,
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.public_off,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Help text for each option
                    Padding(
                      padding: EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        _isProfilePublic
                            ? 'Anyone can find you by name or beavertag'
                            : 'Only people you\'ve transacted with can find you',
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to format Firestore timestamp
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Date unavailable';
  }
}


