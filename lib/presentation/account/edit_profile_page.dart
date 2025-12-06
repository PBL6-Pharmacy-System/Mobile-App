import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/outline_button_app.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/services/api_service.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  String? _avatarUrl;
  String? _gender;
  bool _isLoading = false;
  bool _isSaving = false;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  /// Lấy thông tin khách hàng từ API /customers/{customerId}
  Future<void> _loadCustomerInfo() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null || user.customerId == null) {
      print('⚠️ [EditProfile] No customerId found');
      return;
    }

    _customerId = user.customerId;
    setState(() => _isLoading = true);

    try {
      final dio = ApiService().dio;
      final response = await dio.get('/customers/$_customerId');

      print('📦 [EditProfile] Response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Parse user info from nested 'users' object
        final userData = data['users'];
        if (userData != null) {
          _nameController.text = userData['full_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _avatarUrl = userData['avatar_url'];
        }

        // Parse customer-specific info
        _addressController.text = data['address'] ?? '';
        _gender = data['gender'];

        if (data['dob'] != null) {
          final dob = DateTime.tryParse(data['dob']);
          if (dob != null) {
            _dobController.text =
                '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
          }
        }

        setState(() {});
      }
    } catch (e) {
      print('❌ [EditProfile] Error loading customer info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _avatarFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('❌ [EditProfile] Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Chọn ảnh từ camera
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _avatarFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('❌ [EditProfile] Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Hiển thị dialog chọn nguồn ảnh
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryColor),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_avatarFile != null || _avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Xóa ảnh đại diện',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _avatarFile = null;
                      _avatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lưu thông tin qua API PUT /customers/{customerId}
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ApiService().dio;

      // Prepare data
      final Map<String, dynamic> data = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        if (_gender != null) 'gender': _gender,
      };

      // Parse date of birth
      if (_dobController.text.isNotEmpty) {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            data['dob'] =
                '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          }
        }
      }

      // If there's a new avatar file, upload to server first and get URL
      if (_avatarFile != null) {
        // Upload avatar file to get URL
        final avatarUrl = await _uploadAvatarFile(_avatarFile!);
        if (avatarUrl != null) {
          data['avatar_url'] = avatarUrl;
        } else {
          // Avatar upload failed, but continue with other updates
          print(
            '⚠️ [EditProfile] Avatar upload failed, updating other info only',
          );
        }
      } else if (_avatarUrl == null) {
        // User removed avatar
        data['avatar_url'] = '';
      }

      // Send JSON data (not multipart)
      final response = await dio.put('/customers/$_customerId', data: data);

      if (response.statusCode == 200) {
        _showSuccessAndPop();
      } else {
        throw Exception(response.data['error'] ?? 'Lỗi cập nhật thông tin');
      }
    } on DioException catch (e) {
      print('❌ [EditProfile] DioException: ${e.message}');
      print('❌ [EditProfile] Response: ${e.response?.data}');

      String errorMessage = 'Không thể cập nhật thông tin';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['error'] ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('❌ [EditProfile] Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Upload avatar file to server and return URL
  Future<String?> _uploadAvatarFile(File file) async {
    try {
      print('📤 [EditProfile] Uploading avatar file: ${file.path}');
      final dio = ApiService().dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'type': 'avatar',
      });

      final response = await dio.post(
        '/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('📤 [EditProfile] Upload response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assume server returns {url: '...'} or {data: {url: '...'}}
        final data = response.data;
        if (data is Map) {
          final url = data['url'] ?? data['data']?['url'];
          print('📤 [EditProfile] Avatar URL: $url');
          return url;
        }
      }
      return null;
    } catch (e) {
      print('❌ [EditProfile] Error uploading avatar: $e');
      return null;
    }
  }

  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật thông tin thành công!'),
        backgroundColor: Colors.green,
      ),
    );

    // Refresh user data in AuthProvider
    context.read<AuthProvider>().refreshUser();

    Navigator.pop(context, true);
  }

  /// Chọn ngày sinh
  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );

    if (_dobController.text.isNotEmpty) {
      final parsed = _parseDateString(_dobController.text);
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    // Đảm bảo initialDate nằm trong khoảng cho phép
    final now = DateTime.now();
    if (initialDate.isAfter(now)) {
      initialDate = now.subtract(const Duration(days: 365 * 20));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Parse date string theo format D/M/YYYY hoặc DD/MM/YYYY
  DateTime? _parseDateString(String text) {
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          // Validate ngày hợp lệ
          if (day >= 1 &&
              day <= 31 &&
              month >= 1 &&
              month <= 12 &&
              year >= 1900) {
            final date = DateTime(year, month, day);
            // Kiểm tra ngày có tồn tại không (vd: 30/2/2000 không hợp lệ)
            if (date.day == day && date.month == month && date.year == year) {
              return date;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing date: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa thông tin',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.md),
              child: Column(
                children: [
                  // Ảnh đại diện
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _getAvatarImage(),
                              child: _shouldShowInitial()
                                  ? Text(
                                      _getInitial(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.smHeight,
                        const Text(
                          'Nhấn để thay đổi ảnh đại diện',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  Gap.mLHeight,

                  // Form thông tin cá nhân
                  Container(
                    padding: const EdgeInsets.all(Gap.mL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Họ và tên
                          TextFieldApp(
                            controller: _nameController,
                            labelText: 'Họ và tên *',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ tên';
                              }
                              return null;
                            },
                          ),
                          Gap.sMHeight,

                          // Email
                          TextFieldApp(
                            controller: _emailController,
                            labelText: 'Email *',
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          Gap.sMHeight,

                          // Số điện thoại
                          TextFieldApp(
                            controller: _phoneController,
                            labelText: 'Số điện thoại *',
                            prefixIcon: const Icon(
                              Icons.phone_android_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                                return 'Số điện thoại phải có 10 chữ số';
                              }
                              return null;
                            },
                          ),
                          Gap.sMHeight,

                          // Ngày sinh
                          GestureDetector(
                            onTap: _selectDate,
                            child: AbsorbPointer(
                              child: TextFieldApp(
                                controller: _dobController,
                                labelText: 'Ngày sinh',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                                hintText: 'DD/MM/YYYY',
                              ),
                            ),
                          ),
                          Gap.sMHeight,

                          // Giới tính
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: InputDecoration(
                              labelText: 'Giới tính',
                              prefixIcon: const Icon(Icons.wc_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Nam',
                                child: Text('Nam'),
                              ),
                              DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                            ],
                            onChanged: (value) {
                              setState(() => _gender = value);
                            },
                          ),
                          Gap.sMHeight,

                          // Địa chỉ
                          TextFieldApp(
                            controller: _addressController,
                            labelText: 'Địa chỉ',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            maxLines: 2,
                          ),
                          Gap.mLHeight,

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlineButtonApp(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                              ),
                              const SizedBox(width: Gap.md),
                              Expanded(
                                child: ButtonApp(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_outlined,
                                          color: Colors.white,
                                        ),
                                  child: Text(
                                    _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Gap.mLHeight,

                  // Xóa tài khoản
                  TextButton(
                    onPressed: () {
                      // TODO: Implement delete account
                    },
                    child: const Text(
                      'Xóa tài khoản',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  bool _shouldShowInitial() {
    return _avatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty);
  }

  String _getInitial() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }
}
