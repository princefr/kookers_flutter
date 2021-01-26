import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kookers/Blocs/IbanBloc.dart';
import 'package:kookers/Services/DatabaseProvider.dart';
import 'package:kookers/Widgets/StreamButton.dart';
import 'package:kookers/Widgets/TopBar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';



class AddIbanPage extends StatefulWidget {
  AddIbanPage({Key key}) : super(key: key);

  @override
  _AddIbanPageState createState() => _AddIbanPageState();
}

class _AddIbanPageState extends State<AddIbanPage> {
  final StreamButtonController _streamButtonController = StreamButtonController();

  IbanBloc bloc = IbanBloc();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() { 
    this.bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final databaseService = Provider.of<DatabaseProviderService>(context, listen: false);
    
    return Scaffold(
          body: SafeArea(
                      child: Container(
            child: Column(children: [

              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    height: 7,
                    width: 80),
              ),
              
            SizedBox(height: 30),
            Text("Ajouter un iban", style: GoogleFonts.montserrat(fontSize: 20),),

              SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: StreamBuilder<String>(
                stream: this.bloc.iban$,
                builder: (context, snapshot) {
                  return Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey),
                    child: TextField(
                      onChanged: this.bloc.inBan.add,
                      decoration: InputDecoration(
                        hintText: 'Renseignez un iban',
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                      )
                    ),
                  );
                }
              ),
            ),

                                
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: Text(
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.",
                        style: GoogleFonts.montserrat(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontSize: 10))),
                                ),
            

            Expanded(child: SizedBox()),

            StreamBuilder<String>(
              stream: this.bloc.iban$,
              builder: (context, snapshot) {
                return StreamButton(buttonColor: snapshot.data != null ? Color(0xFFF95F5F) : Colors.grey,
                                     buttonText: "Ajouter l'iban",
                                     errorText: "Une erreur s'est produite, reessayer",
                                     loadingText: "Ajout en cours",
                                     successText: "Iban ajouté",
                                      controller: _streamButtonController, onClick: snapshot.data == null ? null :  () async {
                                        _streamButtonController.isLoading();
                                        databaseService.createBankAccount(snapshot.data).then((value) {
                                            this.bloc.iban.sink.add(null);
                                            _streamButtonController.isSuccess();
                                            databaseService.listExternalAccount();
                                            Navigator.pop(context);
                                        }).catchError((onError) {
                                           _streamButtonController.isError();
                                        });
                                        
                                      });
              }
            )


              ],)
        ),
          ),
    );
  
  }
}


class IbanPage extends StatefulWidget {
  const IbanPage({Key key}) : super(key: key);

  @override
  _IbanPageState createState() => _IbanPageState();
}

class _IbanPageState extends State<IbanPage> {

  @override
  void initState() { 
    new Future.delayed(Duration.zero, (){
      final databaseService = Provider.of<DatabaseProviderService>(context, listen: false);
      databaseService.listExternalAccount().then((value){
        databaseService.userBankAccounts.add(value);
      });
    });
    super.initState();
    
  }
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseProviderService>(context, listen: false);
    return Scaffold(
            appBar: TopBarWitBackNav(
            title: "Iban",
            rightIcon: CupertinoIcons.plus,
            isRightIcon: true,
            height: 54,
            onTapRight: () {

        showCupertinoModalBottomSheet(
              expand: false,
              context: context,
              builder: (context) => AddIbanPage(),
                                  );
            }),
            
            body: SafeArea(
              child: StreamBuilder<List<BankAccount>>(
                  stream: databaseService.userBankAccounts.stream,
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.waiting) return LinearProgressIndicator();
                    if(snapshot.hasError) return Text("i've a bad felling");
                    if(snapshot.data.isEmpty) return Text("its empty out there");
                    return ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (ctx, index){
                        return ListTile(
                          title: Text("*************" + " " + snapshot.data[index].last4),
                          trailing: Icon(CupertinoIcons.check_mark_circled, color: Colors.green,),
                        );
                    });
                  }
                ),
            ),
    );
  }
}