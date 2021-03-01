import 'package:circular_check_box/circular_check_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:kookers/Services/DatabaseProvider.dart' as db;
import 'package:kookers/Services/DatabaseProvider.dart';
import 'package:kookers/TabHome/TabHome.dart';
import 'package:kookers/Widgets/TopBar.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class HomeSearchPage extends StatefulWidget {
   db.Adress adress;
   bool isReturn;
   bool isNotAuth;
  HomeSearchPage({Key key, this.adress, @required this.isReturn, @required this.isNotAuth}) : super(key: key);

  @override
  _HomeSearchPageState createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<HomeSearchPage> with AutomaticKeepAliveClientMixin<HomeSearchPage>  {
    @override
  bool get wantKeepAlive => true;

  GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  DetailsResult detailresult;
  TextEditingController textController = TextEditingController();

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions;
      });
    }
  }

  @override
  void initState() {
    
    googlePlace = GooglePlace("AIzaSyAbJoAWoANYPFagvaiNOAd8vJZGY7SV0Hs");
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }


    Future<void> updateUserAdresses(GraphQLClient client, String uid, List<db.Adress> adresses, DatabaseProviderService database) async {
    final MutationOptions _options = MutationOptions(documentNode: gql(r"""
              mutation UpdateUserAdresses($userID: String!, $adresses: [AdressInput]!) {
                updateUserAdresses(userID: $userID, adresses: $adresses){
              _id
              email
              first_name
              last_name
              is_seller
              phonenumber
              customerId
              country
              currency
              default_source
              default_iban
              stripe_account
              settings {
                  food_preferences
                  food_price_ranges
                  distance_from_seller
                  updatedAt
              }

              stripeAccount {
                charges_enabled
                payouts_enabled
                requirements {
                      currently_due
                      eventually_due
                      past_due
                      pending_verification
                      disabled_reason
                      current_deadline
                }
              }

              balance {
                current_balance
                pending_balance
                currency
              }

              transactions {
                    id
                    object
                    amount
                    available_on
                    created
                    currency
                    description
                    fee
                    net
                    reporting_category
                    type
                    status
              }

              all_cards {
                id
                brand
                country
                customer
                cvc_check
                exp_month
                exp_year
                fingerprint
                funding
                last4
              }

              ibans {
                    id
                    object
                    account_holder_name
                    account_holder_type
                    bank_name
                    country
                    currency
                    last4
              }

              createdAt
              photoUrl
              updatedAt
              adresses {title, location {latitude, longitude}, is_chosed}
              fcmToken
                  }
              }
          """), variables: <String, dynamic>{
          "userID": uid,
          "adresses": db.Adress.toJson(adresses)
        });

        return client.mutate(_options).then((kooker) {
                  final kookersUser = UserDef.fromJson(kooker.data["updateUserAdresses"]);
                  database.user.add(kookersUser);
      });
  }





  @override
  Widget build(BuildContext context) {
    super.build(context);
    final databaseService = Provider.of<DatabaseProviderService>(context, listen: false);

      final firebaseUser = context.watch<User>();

      return Scaffold(
        appBar: TopBarBackCross(height: 54, title:"Choisir une adresse"),
        body: SafeArea(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 45,
                  width: MediaQuery.of(context).size.width,
                  child: TextField(
                    controller: textController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        autoCompleteSearch(value);
                      } else {
                        if (predictions.length > 0 && mounted) {
                          setState(() {
                            predictions = [];
                          });
                        }
                      }
                    },

                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(
                          left: 15, bottom: 11, top: 11, right: 15),
                      hintText: "Rechercher un lieu",
                      prefixIcon: Icon(CupertinoIcons.search),
                      fillColor: Colors.grey[300],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                    ),
                  ),
                ),

                Divider(),

                Visibility(
                  visible: (this.textController?.value?.text?.isNotEmpty),
                  child: 
                    Expanded(
                    child: ListView.builder(
                      dragStartBehavior: DragStartBehavior.down,
                        itemCount: predictions.length,
                        itemBuilder: (ctx, index) {
                          return ListTile(
                            autofocus: false,
                            onTap: () async {
                              googlePlace.details.get(predictions[index].placeId).then((value) {
                                final c = db.Adress(isChosed: true, location: db.Location(latitude: value.result.geometry.location.lat, longitude: value.result.geometry.location.lng),  title: predictions[index].description);
                              setState(() {
                              this.widget.adress = c;
                                if(this.widget.isReturn == false && this.widget.isNotAuth == false) {
                                if(databaseService.adress != null){
                                  databaseService.adress.add(c);
                                  databaseService.loadPublication(c.location, 45);
                                  Navigator.pop(context);
                                }else{
                                  databaseService.user.value.adresses.forEach((e) => e.isChosed = false);
                                  databaseService.user.value.adresses.add(c);
                                  textController.text = "";
                                  this.updateUserAdresses(databaseService.client, firebaseUser.uid, databaseService.user.value.adresses, databaseService).then((value) {
                                        db.Location location = databaseService.user == null ? databaseService.adress.value.location : databaseService.user.value.adresses.firstWhere((element) => element.isChosed).location;
                                        int distance  = databaseService.user == null ? 45 : databaseService.user.value.settings.distanceFromSeller;
                                    databaseService.loadPublication(location, distance).then((value) => Navigator.pop(context));
                                  });
                                }
                              }else if(this.widget.isNotAuth){
                                databaseService.adress.add(c);
                                databaseService.user.add(null);
                                Get.to(TabHome());
                              }
                              else{
                                textController.text = "";
                                Navigator.pop(context, c);
                              }
                              });
                              });
                            },
                            leading: Icon(CupertinoIcons.location),
                            title: Text(predictions[index].description),
                          );
                        }))
                
                ),


                Visibility(
                  visible: (this.textController?.value?.text?.isEmpty),
                  child: Expanded(
                      child: StreamBuilder(
                      stream: databaseService.user$,
                      initialData: databaseService.user.value,
                      builder: (context, AsyncSnapshot<UserDef> snapshot) {
                        if(snapshot.data == null) return SizedBox();
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data.adresses.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              autofocus: false,
                              onTap: (){
                                if(this.widget.isNotAuth){
                                  Get.to(TabHome());
                                }else{
                                  setState(() {
                                    snapshot.data.adresses.forEach((e) => e.isChosed = false);
                                    snapshot.data.adresses[index].isChosed = true;
                                    this.updateUserAdresses(databaseService.client, firebaseUser.uid, databaseService.user.value.adresses, databaseService).then((value) {
                                      db.Location location = databaseService.user == null ? databaseService.adress.value.location : databaseService.user.value.adresses.firstWhere((element) => element.isChosed).location;
                                      int distance  = databaseService.user == null ? 45 : databaseService.user.value.settings.distanceFromSeller;
                                      databaseService.loadPublication(location, distance).then((value) => Navigator.pop(context));
                                      
                                    });
                                  });
                                }
                              },
                              trailing: CircularCheckBox(
                              activeColor: Colors.green,
                              tristate: true,
                              value: snapshot.data.adresses[index].isChosed,
                              onChanged: (bool x) {
                              }),
                              title: Text(snapshot.data.adresses[index].title)
                            );

                        });
                      }
                    ),
                  ))


              ],
            ),
          ),
        ),
      );

  }
}
