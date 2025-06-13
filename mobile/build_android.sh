#!/bin/bash

flutter clean
flutter pub get
flutter pub run flutter_launcher_icons

flutter build apk
flutter install