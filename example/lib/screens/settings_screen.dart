// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:atlas_support_sdk/atlas_support_sdk.dart';

class _DemoUser {
  final String atlasId;
  final String userId;
  final String userHash;
  _DemoUser(this.atlasId, this.userId, this.userHash);
}

var _userAdam = _DemoUser(
    '86427437-8d4e-425c-bae1-109cf7ecbfc5', 'adam', '28af9d7e2fe67562e0b3dc0e4df9ae070be4a286f28fed8bd9eb555b68feb399');
var _userSara = _DemoUser(
    '4ae4ee1b-5925-4059-9932-16cdf60d5ba9', 'sara', 'edceaca5418b1e3bf339af13460236dbae40a335a2d1b8148681adaa2cc5753e');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Function? _dispose;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var userId = AtlasSDK.getUserId();
    if (userId != null) _userIdController.text = userId;

    // Track identity changes

    _dispose = AtlasSDK.onChangeIdentity((identity) {
      if (identity == null) {
        setState(() {
          _userIdController.text = '';
        });
        print("onChangeIdentity(null)");
      } else {
        setState(() {
          _userIdController.text = identity.atlasId == _userAdam.atlasId
              ? _userAdam.userId
            : identity.atlasId == _userSara.atlasId
                ? _userSara.userId
                : '';
        });
        print("onChangeIdentity({atlasId: ${identity.atlasId}})");
      }
    });

  }

  @override
  void dispose() {
    _userIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _titleController.dispose();
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              RadioListTile(
                title: Text('User ID: "${_userAdam.userId}"'),
                value: _userAdam.userId,
                groupValue: _userIdController.text,
                onChanged: (value) {
                  setState(() {
                    _userIdController.text = value as String;
                  });
                },
              ),
              RadioListTile(
                title: Text('User ID: "${_userSara.userId}"'),
                value: _userSara.userId,
                groupValue: _userIdController.text,
                onChanged: (value) {
                  setState(() {
                    _userIdController.text = value as String;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                controller: _nameController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                controller: _emailController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                controller: _phoneNumberController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                controller: _titleController,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final userId = _userIdController.text;
                      final name = _nameController.text;
                      final email = _emailController.text;
                      final phoneNumber = _phoneNumberController.text;
                      final title = _titleController.text;
                      AtlasSDK.identify(
                        userId: userId,
                        userHash: userId == _userAdam.userId
                            ? _userAdam.userHash
                            : userId == _userSara.userId
                                ? _userSara.userHash
                                : null,
                        name: name.trim() != "" ? name : null,
                        email: email.trim() != "" ? email : null,
                        phoneNumber: phoneNumber.trim() != "" ? phoneNumber : null,
                        customFields: {
                          if (title.trim() != "") 'title': title,
                        },
                      );
                    },
                    child: const Text('Identify'),
                  ),
                  const ElevatedButton(
                    onPressed: AtlasSDK.logout,
                    child: Text('Logout'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: false,
                    showDragHandle: true,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.82,
                        child: SafeArea(
                          child: Scaffold(
                            body: AtlasSDK.Widget(
                                persist: "settings-help-center", query: 'open: helpcenter'),
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.help),
                label: const Text('Help Center'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 