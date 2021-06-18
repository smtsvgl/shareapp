import 'dart:io' show Platform;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:glyphicon/glyphicon.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../components/buttons.dart';
import '../components/logo.dart';
import '../components/page_router.dart';
import '../conf.dart';
import '../dialogs/open_dialog.dart';
import '../dialogs/receiver.dart';
import '../dialogs/share_app.dart';
import '../dialogs/share_text.dart';
import '../logic/sharing_object.dart';
import '../logic/theme.dart';
import '../utils/helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SharingObject> _history = <SharingObject>[];

  @override
  void initState() {
    _history = Hive.box<SharingObject>('history').values.toList();

    super.initState();
  }

  Future<void> saveLatest() async {
    await Hive.box<SharingObject>('history').clear();
    await Hive.box<SharingObject>('history').addAll(_history);
  }

  Future<void> shareFile(SharingObject file) async {
    setState(() {
      if (_history.contains(file)) _history.remove(file);

      _history.insert(0, file);
    });

    await saveLatest();

    SharikRouter.navigateTo(
        context, context.widget, Screens.sharing, RouteDirection.right, file);
  }

  // todo fix hoverdb files in the Documents dir on Linux
  // todo scroll history header with listview builder
  // todo review paddings
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: SizedBox(
            height: 22,
          ),
        ),
        Hero(
          tag: 'icon',
          child: SharikLogo(),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            // todo review constraints
            if (constraints.maxWidth < 720) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    sharingButtons(c),
                    const SizedBox(
                      height: 24,
                    ),
                    Expanded(
                      child: sharingHistoryList(c),
                    ),
                  ],
                ),
              );
            } else {
              return Row(
                children: [
                  const SizedBox(width: 24),
                  Expanded(child: sharingButtons(c)),
                  const SizedBox(width: 24),
                  Expanded(child: sharingHistoryList(c)),
                  const SizedBox(width: 24),
                ],
              );
            }
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          height: 64,
          decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: Row(
            children: [
              TransparentButton(
                  SizedBox(
                      height: 20,
                      width: 20,
                      child: Icon(FeatherIcons.globe,
                          color: Colors.deepPurple.shade700, size: 20)),
                  () => SharikRouter.navigateTo(context, context.widget,
                      Screens.languagePicker, RouteDirection.left),
                  TransparentButtonBackground.purpleLight),
              const SizedBox(width: 2),
              TransparentButton(
                SizedBox(
                    height: 20,
                    width: 20,
                    child: Icon(FeatherIcons.helpCircle,
                        color: Colors.deepPurple.shade700, size: 20)),
                () => SharikRouter.navigateTo(context, context.widget,
                    Screens.intro, RouteDirection.left),
                TransparentButtonBackground.purpleLight,
              ),
              const SizedBox(width: 2),
              TransparentButton(
                  SizedBox(
                      height: 20,
                      width: 20,
                      child: Icon(FeatherIcons.download,
                          color: Colors.deepPurple.shade700, size: 20)), () {
                openDialog(context, ReceiverDialog());
              }, TransparentButtonBackground.purpleLight),
              const SizedBox(width: 2),
              TransparentButton(
                  SizedBox(
                      height: 20,
                      width: 20,
                      child: Icon(context.watch<ThemeManager>().icon,
                          color: Colors.deepPurple.shade700, size: 20)),
                  () => context.read<ThemeManager>().change(),
                  TransparentButtonBackground.purpleLight),
              const Spacer(),
              TransparentButton(
                  Text(
                    'sharik v$currentVersion →',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  () => SharikRouter.navigateTo(context, context.widget,
                      Screens.about, RouteDirection.right),
                  TransparentButtonBackground.purpleLight),
            ],
          ),
        ),
        Container(
          color: Colors.deepPurple.shade100,
          child: SafeArea(
            top: false,
            right: false,
            left: false,
            child: Container(),
          ),
        )
      ]),
    );
  }

  Widget sharingHistoryList(BuildContext c) {
    return ListView.builder(
        shrinkWrap: true,
        // todo there's probably a more elegant way to do this
        itemCount: _history.length + 1,
        itemBuilder: (context, index) => index == 0
            ? _sharingHistoryHeader(c)
            : card(context, _history[index - 1]));
  }

  Widget _sharingHistoryHeader(BuildContext c) {
    if (_history.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text(
              c.l.homeHistory,
              style: GoogleFonts.getFont(c.l.fontComfortaa, fontSize: 24),
            ),
            const Spacer(),
            TransparentButton(const Icon(FeatherIcons.trash), () {
              setState(() => _history.clear());

              saveLatest();
            }, TransparentButtonBackground.purpleDark)
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget sharingButtons(BuildContext c) {
    return Column(
      children: [
        PrimaryButton(
          height: 110,
          onClick: () async {
            if (Platform.isAndroid || Platform.isIOS) {
              final f = await FilePicker.platform.pickFiles();

              if (f != null) {
                shareFile(SharingObject(
                    data: (f.paths.first)!,
                    type: SharingObjectType.file,
                    name: SharingObject.getSharingName(
                        SharingObjectType.file, (f.paths.first)!)));
              }
            } else {
              final f = await openFile();
              if (f != null) {
                shareFile(SharingObject(
                  data: f.path,
                  type: SharingObjectType.file,
                  name: SharingObject.getSharingName(
                      SharingObjectType.file, f.path),
                ));
              }
            }
          },
          text: c.l.homeSelectFile,
          secondaryIcon: Icon(
            Glyphicon.file_earmark,
            size: 48,
            color: Colors.deepPurple.shade200.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (Platform.isAndroid)
              Expanded(
                child: PrimaryButton(
                  height: 50,
                  onClick: () async {
                    final f = await openDialog(context, ShareAppDialog());
                    if (f != null) {
                      shareFile(f);
                    }
                  },
                  text: c.l.homeSelectApp,
                ),
              ),
            if (Platform.isIOS)
              Expanded(
                child: PrimaryButton(
                  height: 50,
                  onClick: () async {
                    // todo ios gallery
                    // final f =
                    //     await FilePicker.getFile(type: FileType.media);
                    // if (f != null && f.path != null && f.path.isNotEmpty) {
                    //   shareFile(FileModel(
                    //       data: f.path, type: FileTypeModel.file));
                    // }
                  },
                  text: c.l.homeSelectGallery,
                ),
              ),
            if (Platform.isIOS || Platform.isAndroid) const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                height: 50,
                onClick: () async {
                  final f = await openDialog(context, ShareTextDialog());
                  if (f != null) {
                    shareFile(f);
                  }
                },
                text: c.l.homeSelectText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget card(BuildContext c, SharingObject f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListButton(
          Row(
            children: [
              Icon(
                f.icon,
                size: 22,
                color: Colors.grey.shade100,
                // semanticsLabel: 'file',
                // width: 18,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                  child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  f.name,
                  style: GoogleFonts.getFont(c.l.fontAndika,
                      color: Colors.white, fontSize: 18),
                  maxLines: 1,
                ),
              ))
            ],
          ),
          () => shareFile(f)),
    );
  }
}
