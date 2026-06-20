import 'package:dorna/utils/utils.dart';
import 'package:dorna/widgets/ui/back_header.dart';
import 'package:dorna/widgets/ui/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  static const String routeName = '/contact_us';

  const ContactUsScreen({Key? key}) : super(key: key);

  final String _email = 'support@thedorna.com';
  final String _phone = '09237837477234';
  final String _address = '777 Fort Street, Victoria, BC V8W 1G9, Canada';

  Future<void> _launchEmail() async {
    final Uri uri = Uri(scheme: 'mailto', path: _email);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone() async {
    final Uri uri = Uri(scheme: 'tel', path: _phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    showCustomToast(
      'Copied to clipboard',
      context,
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const BackHeader(title: 'Contact us'),
              const SizedBox(height: 24),
              _ContactRow(
                icon: 'assets/icons/ic_email.svg',
                label: 'Email',
                value: _email,
                onTap: _launchEmail,
                onLongPress: () => _copyToClipboard(_email, context),
              ),
              const SizedBox(height: 16),
              // _ContactRow(
              //   icon: 'assets/icons/ic_phone.svg',
              //   label: 'Phone',
              //   value: _phone,
              //   onTap: _launchPhone,
              //   onLongPress: () => _copyToClipboard(_phone, context),
              // ),
              // const SizedBox(height: 16),
              _ContactRow(
                icon: 'assets/icons/ic_location.svg',
                label: 'Address',
                value: _address,
                multiline: true,
                onTap: () => _copyToClipboard(
                  _address,
                  context,
                ),
                onLongPress: () => _copyToClipboard(
                  _address,
                  context,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool multiline;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ContactRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onLongPress,
    this.multiline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final TextStyle labelStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 13.sp,
            );
    final TextStyle valueStyle =
        Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: cs.onSurface,
              fontSize: 14.sp,
            );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment:
              multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Row(
                children: [
                  SvgPicture.asset(
                    icon,
                    width: 18,
                    height: 18,
                    color: cs.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(label, style: labelStyle))),
                ],
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: valueStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
