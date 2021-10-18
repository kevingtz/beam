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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playground/modules/shortcuts/models/shortcut.dart';
import 'package:playground/pages/playground/states/playground_state.dart';
import 'package:provider/provider.dart';

const kRunText = 'Run';
const kResetText = 'Reset';
const kClearText = 'Clear';

class ResetIntent extends Intent {
  const ResetIntent();
}

class RunIntent extends Intent {
  const RunIntent();
}

class ClearIntent extends Intent {
  const ClearIntent();
}

final List<Shortcut> globalShortcuts = [
  Shortcut(
    shortcuts: LogicalKeySet(
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.digit0,
    ),
    actionIntent: const RunIntent(),
    name: kRunText,
    createAction: (BuildContext context) => CallbackAction(
      onInvoke: (_) => Provider.of<PlaygroundState>(
        context,
        listen: false,
      ).runCode(),
    ),
  ),
  Shortcut(
    shortcuts: LogicalKeySet(
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.digit9,
    ),
    actionIntent: const ResetIntent(),
    name: kResetText,
    createAction: (BuildContext context) => CallbackAction(
      onInvoke: (_) => Provider.of<PlaygroundState>(
        context,
        listen: false,
      ).reset(),
    ),
  ),
];
