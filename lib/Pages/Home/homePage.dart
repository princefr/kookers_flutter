import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kookers/Pages/Home/FoodIemChild.dart';
import 'package:kookers/Pages/Home/FoodItem.dart';
import 'package:kookers/Pages/Home/Guidelines.dart';
import 'package:kookers/Pages/Home/HomePublish.dart';
import 'package:kookers/Pages/Home/HomeSearchPage.dart';
import 'package:kookers/Pages/Home/HomeSettings.dart';
import 'package:kookers/Services/DatabaseProvider.dart';
import 'package:kookers/Widgets/EmptyView.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

class HomeTopBar extends PreferredSize {
  final double height;
  const HomeTopBar({Key key, this.height});

  @override
  Size get preferredSize => Size.fromHeight(height);

  Widget build(BuildContext context) {
    final databaseService =
        Provider.of<DatabaseProviderService>(context, listen: true);

    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  child: SvgPicture.asset(
                                'assets/logo/logo_white.svg',
                                height: 30,
                                width: 30,
                              ),
                ),

                            SizedBox(width: 10),
                Text("Kookers",
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: Colors.black)),
              ],
            ),
            Row(
              children: [
                InkWell(
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        expand: false,
                        context: context,
                        builder: (context) => HomeSettings(),
                      );
                    },
                    child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: new BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.slider_horizontal_3,
                            size: 23.0, color: Colors.black))),
                Flexible(
                  child: ListTile(
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        expand: false,
                        context: context,
                        builder: (context) => HomeSearchPage(isReturn: false),
                      );
                    },
                    title: StreamBuilder(
                        initialData: null,
                        stream: databaseService.user$,
                        builder: (context, AsyncSnapshot<UserDef> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return SizedBox(
                                height: 25,
                                width: 400,
                                child: Shimmer.fromColors(
                                    enabled: true,
                                    child: Container(color: Colors.white),
                                    baseColor: Colors.grey[200],
                                    highlightColor: Colors.grey[300]));
                          return Text(
                              snapshot.data.adresses
                                  .where((element) => element.isChosed == true)
                                  .first
                                  .title,
                              style: GoogleFonts.montserrat(fontSize: 17),
                              overflow: TextOverflow.ellipsis);
                        }),
                    trailing: Icon(CupertinoIcons.chevron_down,
                        size: 24.0, color: Colors.grey),
                  ),
                )
              ],
            ),
            Divider()
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin<HomePage>  {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final databaseService =
        Provider.of<DatabaseProviderService>(context, listen: false);

    return Scaffold(
      appBar: HomeTopBar(
        height: 144,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFF95F5F),
        onPressed: () {
            if(databaseService.user.value.isSeller == false) {
                showCupertinoModalBottomSheet(
                  expand: true,
                  context: context,
                  builder: (context) => GuidelinesToSell(),
                );
            }else{
              showCupertinoModalBottomSheet(
                  expand: true,
                  context: context,
                  builder: (context) => HomePublish(),
                );
            }
        },
        child: Icon(CupertinoIcons.pencil, size: 34.0, color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<PublicationHome>>(
            stream: databaseService.publications$,
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Shimmer.fromColors(
                    child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (ctx, index) {
                          return FoodItemShimmer();
                        }),
                    baseColor: Colors.grey[200],
                    highlightColor: Colors.grey[300]);
              if (snapshot.hasError) return Text("i've a bad felling");
              if (snapshot.data.isEmpty)
                return SmartRefresher(
                    enablePullDown: true,
                    enablePullUp: false,
                    controller: this._refreshController,
                    onRefresh: () {
                      databaseService.loadPublication().then((value) {
                        Future.delayed(Duration(milliseconds: 500))
                            .then((value) {
                          _refreshController.refreshCompleted();
                        });
                      });
                    },
                    child: EmptyViewElse(text: "Aucune vente à proximité"));

              return SmartRefresher(
                enablePullDown: true,
                enablePullUp: false,
                controller: this._refreshController,
                onRefresh: () {
                  databaseService.loadPublication().then((value) {
                    Future.delayed(Duration(milliseconds: 500)).then((value) {
                      _refreshController.refreshCompleted();
                    });
                  });
                },
                child: ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (ctx, index) {
                    return FoodItem(
                        publication: snapshot.data[index],
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FoodItemChild(
                                      publication: snapshot.data[index])));
                        });
                  },
                ),
              );
            }),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
