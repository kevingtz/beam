/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playground_components/playground_components.dart';

import 'login/content.dart';
import 'profile/user_menu.dart';

void kOpenLoginOverlay(BuildContext context, [User? user]) {
  final overlayCloser = PublicNotifier();
  final overlay = OverlayEntry(
    builder: (context) {
      return DismissibleOverlay(
        close: overlayCloser.notifyPublic,
        child: Positioned(
          right: BeamSizes.size10,
          top: BeamSizes.appBarHeight,
          child: user == null
              ? LoginContent(
                  onLoggedIn: overlayCloser.notifyPublic,
                )
              : UserMenu(
                  onLoggedOut: overlayCloser.notifyPublic,
                  user: user,
                ),
        ),
      );
    },
  );
  overlayCloser.addListener(overlay.remove);
  Overlay.of(context)?.insert(overlay);
}
