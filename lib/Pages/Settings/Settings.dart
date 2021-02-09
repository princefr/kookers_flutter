import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kookers/Pages/Balance/BalancePage.dart';
import 'package:kookers/Pages/Iban/IbanPage.dart';
import 'package:kookers/Pages/PaymentMethods/PaymentMethodPage.dart';
import 'package:kookers/Pages/Verification/VerificationPage.dart';
import 'package:kookers/Services/AuthentificationService.dart';
import 'package:kookers/Services/DatabaseProvider.dart';
import 'package:kookers/Services/StorageService.dart';
import 'package:kookers/Widgets/PageTitle.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsItemWithLeftIcon extends StatelessWidget {
  final Function onTap;
  final String buttonText;
  final IconData icon;
  const SettingsItemWithLeftIcon(
      {Key key, @required this.onTap, @required this.buttonText, @required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    
    return Material(
        child: InkWell(
      onTap: this.onTap,
      child: Container(
        color: Colors.white,
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: ListTile(
            leading: Icon(this.icon),
            title: Text(this.buttonText,
                style: GoogleFonts.montserrat(fontSize: 16)),
            trailing: Icon(CupertinoIcons.chevron_right),
          ),
        ),
      ),
    ));
  }
}

class SettingsItem extends StatelessWidget {
  final Function onTap;
  final String buttonText;
  const SettingsItem({Key key, @required this.onTap, @required this.buttonText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        child: InkWell(
      onTap: this.onTap,
      child: Container(
        color: Colors.white,
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: ListTile(
            title: Text(this.buttonText,
                style: GoogleFonts.montserrat(fontSize: 16)),
            trailing: Icon(CupertinoIcons.chevron_right),
          ),
        ),
      ),
    ));
  }
}

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

 


String capitalizeFirstOnly(String string){
  return string.characters.first.toUpperCase() + string.substring(1);
}

  final picker = ImagePicker();

  Future<File> getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    return File(pickedFile.path);
  }

  Future<void> updateUserImage(GraphQLClient client, String uid, String imageUrl, DatabaseProviderService database) {
    final MutationOptions _options = MutationOptions(documentNode: gql(r"""
              mutation UpdateUserImage($userID: String!, $imageUrl: String!) {
                  updateUserImage(userID: $userID, imageUrl: $imageUrl){
                _id
                firebaseUID
                email
                first_name
                last_name
                phonenumber
                settings {
                    food_preferences
                    food_price_ranges
                    distance_from_seller
                    updatedAt
                }

                createdAt
                photoUrl
                updatedAt
                adresses {title, location {latitude, longitude}, is_chosed}
                fcmToken
                rating {rating_total, rating_count}
                  }
              }
          """), variables: <String, String>{
          "userID": uid,
          "imageUrl": imageUrl
        });

        return client.mutate(_options).then((kooker) {
                  final kookersUser = UserDef.fromJson(kooker.data["updateUserImage"]);
                  database.user.add(kookersUser);
      });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    final storageService = Provider.of<StorageService>(context, listen: false);
    final authentificationService = Provider.of<AuthentificationService>(context, listen: false);
    final databaseService = Provider.of<DatabaseProviderService>(context, listen: true);




    return Container(
      child: ListView(
        children: [
        PageTitle(title: "Paramètres"),
        SizedBox(height: 20),

        Container(
          height: 130,
          margin: EdgeInsets.symmetric(vertical: 10.0),
          child: Stack(children: [
            Center(
              child: StreamBuilder(
                stream: databaseService.user.stream,
                builder: (context, AsyncSnapshot<UserDef> snapshot) {
                  if(snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
                  return CircleAvatar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.white,
                  radius: 65,
                backgroundImage: CachedNetworkImageProvider(snapshot.data.photoUrl,),
              );
                }
              ),
            ),

            Positioned(
              bottom: 0,
              left: 205,
              child: InkWell(
                onTap: () {
                  this.getImage().then((file) => {
                    storageService.uploadPictureFile(firebaseUser.uid, "photoUrl.jpg", file).then((url) => {
                      this.updateUserImage(databaseService.client, firebaseUser.uid, url, databaseService)
                    })
                  }).catchError((onError){
                    print(onError);
                  });
                },
                child: Container(
                    padding: EdgeInsets.symmetric(vertical: 7.0, horizontal: 7),
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 43, 84),
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20.0,
                    )),
              ),
            )
          ]),
        ),
        
        SizedBox(height: 20),
        Center(
            child: Text(databaseService.user.value.lastName.toUpperCase() + " " + capitalizeFirstOnly(databaseService.user.value.firstName),
                style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87))),
        SizedBox(height: 15),
        Divider(),
        SettingsItemWithLeftIcon(
          icon: Icons.credit_card_sharp,
            buttonText: "Methodes de paiements",
            onTap: () => Navigator.push(context,
                CupertinoPageRoute(builder: (context) => PaymentMethodPage()))),

        SettingsItemWithLeftIcon(
          icon: Icons.account_balance_wallet_sharp,
            buttonText: "Portefeuille",
            onTap: () => Navigator.push(context,
                CupertinoPageRoute(builder: (context) => BalancePage()))),


        SettingsItemWithLeftIcon(
          icon: Icons.account_balance,
            buttonText: "Comptes bancaires",
            onTap: () => Navigator.push(context,
                CupertinoPageRoute(builder: (context) => IbanPage()))),

        SettingsItem(
            onTap: () {
              Navigator.push(context,
                CupertinoPageRoute(builder: (context) => VerificationPage()));
              
            }, buttonText: "Vérification d'identité"),

        SettingsItem(
            onTap: () {
              launch("https://getkookers.com/terms");
              
            }, buttonText: "Conditions générale d'utilisation"),
        SettingsItem(onTap: () {
            launch("http://getkookers.com/privacy");
        }, buttonText: "Politique de confidentialité"),
        SettingsItem(onTap: () {
          launch("http://getkookers.com/privacy");
        }, buttonText: "Gestion des cookies"),

                SettingsItem(onTap: () {
          launch("https://getkookers.com/guidelines");
        }, buttonText: "Règles de la communauté"),

        SettingsItem(onTap: () {
            print("i'm signign out");
            authentificationService.signOut();
        }, buttonText: "Se deconnecter"),
      ]),
    );


  }


  
}
