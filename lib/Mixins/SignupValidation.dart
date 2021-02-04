import 'dart:async';

import 'package:kookers/Services/DatabaseProvider.dart';




mixin SignupValidation {
  static bool isNotEmpty(String text) => text.isNotEmpty;
  static bool isEmailValid(String email) => RegExp(r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$').hasMatch(email);


  final validateFirstName = StreamTransformer<String, String>.fromHandlers(handleData: (value, sink) {
  if(value != null) {
      if(value.isNotEmpty){
      sink.add(value);
    } else{
      sink.addError("Veuillez renseigner votre prénom");
    }
  }
  });

    final validateLastName = StreamTransformer<String, String>.fromHandlers(handleData: (value, sink) {
      if(value != null) {
          if(value.isNotEmpty){
          sink.add(value);
        } else{
          sink.addError("Veuillez renseigner votre nom");
        }
      }
    });


    final validateEmail = StreamTransformer<String, String>.fromHandlers(handleData: (value, sink) {
      if(value != null && isEmailValid(value))  {
          sink.add(value);
      }else{
        sink.addError("Veuillez renseigner votre email");
      }
    });


    final validatePoliciesAccepted = StreamTransformer<bool, bool>.fromHandlers(handleData: (value, sink) {
      if(value != null) {
          if(value){
          sink.add(value);
        } else{
          sink.addError("Veuillez accepter nos politiques pour continuer");
        }
      }
    });


    final validateAdress = StreamTransformer<Adress, Adress>.fromHandlers(handleData: (value, sink) {
      if(value != null) {
          if(value.title.isNotEmpty){
          sink.add(value);
        } else{
          sink.addError("Veuillez renseigner votre adresse");
        }
      }
    });

    final validatebirthDate = StreamTransformer<DateTime, DateTime>.fromHandlers(handleData: (value, sink) {
      if(value != null) {
        sink.add(value);
      }else{
        sink.addError("Veuillez renseigner votre date de naissance");
      }
    });


        

}