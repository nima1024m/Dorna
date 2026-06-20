import 'package:dorna/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSheet extends StatelessWidget {
  final Function(XFile) onImagePicked;
  final Function() onRemoveImage;
  final bool hasCurrentImage;

  const ImagePickerSheet({
    Key? key,
    required this.onImagePicked,
    required this.onRemoveImage,
    required this.hasCurrentImage,
  }) : super(key: key);

  Future<void> _pickImageFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (image != null) {
      onImagePicked(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xff252525).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          children: <Widget>[
            if (hasCurrentImage)
              ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                  child: Text(
                  'Remove Photo',
                  style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                      ?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 16.sp),
                )),
              onTap: () {
                Navigator.of(context).pop();
                  onRemoveImage();
                },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                  child: Text(
                'Take Photo',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white, fontSize: 16.sp),
              )),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                  child: Text(
                'Choose from Gallery',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white, fontSize: 16.sp),
              )),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
