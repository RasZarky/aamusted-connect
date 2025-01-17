import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../helper/enum.dart';
import '../../../../../../state/searchState.dart';
import '../../../../../../widgets/customAppBar.dart';
import '../../../../../../widgets/customWidgets.dart';
import '../../../../../../widgets/newWidget/title_text.dart';
import '../../../../../theme/theme.dart';
import '../../../widgets/settingsRowWidget.dart';

class TrendsPage extends StatelessWidget {
  const TrendsPage({Key? key}) : super(key: key);

  void openBottomSheet(
      BuildContext context, double height, Widget child) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: TwitterColor.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: child,
        );
      },
    );
  }

  void openUserSortSettings(BuildContext context) {
    openBottomSheet(
      context,
      340,
      Column(
        children: <Widget>[
          const SizedBox(height: 5),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: TwitterColor.paleSky50,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: TitleText('Sort user list'),
          ),
          const Divider(height: 0),
          _row(context, "Verified user", SortUser.Verified),
          const Divider(height: 0),
          _row(context, "Alphabetically", SortUser.Alphabetically),
          const Divider(height: 0),
          _row(context, "Newest user", SortUser.Newest),
          const Divider(height: 0),
          _row(context, "Oldest user", SortUser.Oldest),
          const Divider(height: 0),
          _row(context, "Popular User", SortUser.MaxFollower),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String text, SortUser sortBy) {
    final state = Provider.of<SearchState>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
      child: RadioListTile<SortUser>(
        value: sortBy,
        activeColor: TwitterColor.dodgeBlue,
        groupValue: state.sortBy,
        onChanged: (val) {
          context.read<SearchState>().updateUserSortPrefrence = val!;
          Navigator.pop(context);
        },
        title: Text(text, style: TextStyles.subtitleStyle),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwitterColor.white,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText('Trends'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          SettingRowWidget(
            "Search Filter",
            subtitle:
                context.select((SearchState value) => value.selectedFilter),
            onPressed: () {
              openUserSortSettings(context);
            },
            showDivider: false,
          ),
          const SettingRowWidget(
            "Trends location",
            navigateTo: null,
            subtitle: 'AAMUSTED campus',
            showDivider: false,
          ),
          const SettingRowWidget(
            null,
            subtitle:
                'You can see what\'s trending in a specfic location by selecting which location appears in your Trending tab.',
            navigateTo: null,
            showDivider: false,
            vPadding: 12,
          ),
        ],
      ),
    );
  }
}
