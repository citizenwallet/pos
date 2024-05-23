import 'package:flutter/material.dart';
import 'package:scanner/services/web3/contracts/profile.dart';
import 'package:scanner/state/profile/logic.dart';
import 'package:scanner/state/profile/state.dart';
import 'package:scanner/state/scan/state.dart';
import 'package:scanner/utils/delay.dart';
import 'package:scanner/utils/formatters.dart';
import 'package:scanner/widget/blurry_child.dart';
import 'package:scanner/widget/progress_bar.dart';
import 'package:scanner/widget/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final UsernameFormatter usernameFormatter = UsernameFormatter();
  final NameFormatter nameFormatter = NameFormatter();

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  late ProfileLogic _logic;

  late Debounce debouncedHandleUsernameUpdate;
  late Debounce debouncedHandleNameUpdate;
  late Debounce debouncedHandleDescriptionUpdate;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);

    debouncedHandleUsernameUpdate = debounce(
      (String username) {
        _logic.checkUsername(username);
      },
      const Duration(milliseconds: 500),
    );

    debouncedHandleNameUpdate = debounce(
      (String username) {
        _logic.updateNameErrorState(username);
      },
      const Duration(milliseconds: 250),
    );

    debouncedHandleDescriptionUpdate = debounce(
      (String username) {
        _logic.updateDescriptionText(username);
      },
      const Duration(milliseconds: 250),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _logic.startEdit();
  }

  @override
  void dispose() {
    debouncedHandleUsernameUpdate.cancel();
    debouncedHandleNameUpdate.cancel();
    debouncedHandleDescriptionUpdate.cancel();
    _logic.resetEdit();
    super.dispose();
  }

  void handleUsernameUpdate(String username) {
    debouncedHandleUsernameUpdate([username]);
  }

  void handleNameUpdate(String name) {
    debouncedHandleNameUpdate([name]);
  }

  void handleDescriptionUpdate(String desc) {
    debouncedHandleDescriptionUpdate([desc]);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.lightImpact();
  }

  void handleSave(Uint8List? image) async {
    final navigator = GoRouter.of(context);

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();

    final vendorAddress = context.read<ScanState>().vendorAddress;

    if (vendorAddress == null) {
      return;
    }

    final success = await _logic.save(
      ProfileV1(
        account: vendorAddress,
      ),
      image,
    );

    if (!success) {
      return;
    }

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleUpdate() async {
    final navigator = GoRouter.of(context);

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();

    final vendorAddress = context.read<ScanState>().vendorAddress;

    if (vendorAddress == null) {
      return;
    }

    final success = await _logic.update(
      ProfileV1(
        account: vendorAddress,
      ),
    );

    if (!success) {
      return;
    }

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleSelectPhoto() {
    HapticFeedback.lightImpact();

    _logic.selectPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((ProfileState state) => state.loading);
    final error = context.select((ProfileState state) => state.error);

    final ready = true;
    final readyLoading = false;

    final updateState =
        context.select((ProfileState state) => state.updateState);

    final image = context.select((ProfileState state) => state.image);
    final editingImage =
        context.select((ProfileState state) => state.editingImage);

    final usernameController = context.watch<ProfileState>().usernameController;
    final usernameLoading =
        context.select((ProfileState state) => state.usernameLoading);
    final usernameError =
        context.select((ProfileState state) => state.usernameError);

    final nameController = context.watch<ProfileState>().nameController;

    final descriptionController =
        context.watch<ProfileState>().descriptionController;
    final descriptionEditText =
        context.select((ProfileState state) => state.descriptionEdit);

    final username = context.select((ProfileState state) => state.username);
    final hasProfile = username.isNotEmpty;

    final isInvalid = usernameError || usernameController.value.text == '';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: hasProfile ? const Text('Edit') : const Text('Create'),
        ),
        body: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ListView(
                        physics: const ScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              editingImage != null
                                  ? ProfileCircle(
                                      size: 160,
                                      imageBytes: editingImage,
                                      // borderColor: ThemeColors.subtle,
                                    )
                                  : ProfileCircle(
                                      size: 160,
                                      imageUrl: image,
                                      // borderColor: ThemeColors.subtle,
                                    ),
                              IconButton(
                                onPressed: handleSelectPhoto,
                                icon: const Icon(
                                  Icons.camera,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Username',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: usernameController,
                            maxLines: 1,
                            maxLength: 30,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onChanged: handleUsernameUpdate,
                            inputFormatters: [
                              usernameFormatter,
                            ],
                            decoration: InputDecoration(
                              prefixIcon: SizedBox(
                                height: 30,
                                width: 30,
                                child: Center(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: usernameLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.grey,
                                          )
                                        : const Icon(
                                            CupertinoIcons.at,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            onSubmitted: (_) {
                              nameFocusNode.requestFocus();
                            },
                          ),
                          const SizedBox(height: 10),
                          if (usernameError)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  usernameController.value.text == ''
                                      ? 'Please pick a username'
                                      : 'This username is already taken',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Name',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nameController,
                            maxLines: 1,
                            maxLength: 50,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onChanged: handleNameUpdate,
                            inputFormatters: [
                              nameFormatter,
                            ],
                            focusNode: nameFocusNode,
                            onSubmitted: (_) {
                              descriptionFocusNode.requestFocus();
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Description',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller:
                                descriptionController, // hack to align to top
                            minLines: 4,
                            maxLines: 8,
                            maxLength: 200,
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            onChanged: handleDescriptionUpdate,
                            focusNode: descriptionFocusNode,
                            textAlignVertical: TextAlignVertical.top,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${descriptionEditText.length} / 200',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          const SizedBox(height: 10),
                          if (!loading && error)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Failed to save',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      width: width,
                      child: BlurryChild(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: Column(
                            children: [
                              if (loading) ...[
                                SizedBox(
                                  height: 25,
                                  child: Center(
                                    child: ProgressBar(
                                      updateState.progress,
                                      width: width - 40,
                                      height: 16,
                                      borderRadius: 8,
                                    ),
                                  ),
                                ),
                                Text(
                                  switch (updateState) {
                                    ProfileUpdateState.existing =>
                                      'Fetching existing profile',
                                    ProfileUpdateState.uploading =>
                                      'Uploaded new profile',
                                    ProfileUpdateState.fetching =>
                                      'Almost done',
                                    _ => 'Saving',
                                  },
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                )
                              ],
                              if (!loading && !readyLoading && ready)
                                TextButton(
                                  onPressed: isInvalid
                                      ? null
                                      : hasProfile && editingImage == null
                                          ? () => handleUpdate()
                                          : () => handleSave(
                                                editingImage,
                                              ),
                                  child: const Text('Save'),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
