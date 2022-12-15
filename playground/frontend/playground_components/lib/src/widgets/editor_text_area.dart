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

// TODO(alexeyinkin): Refactor this, merge into snippet_editor.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../controllers/snippet_editing_controller.dart';
import '../theme/theme.dart';

class EditorTextArea extends StatefulWidget {
  final SnippetEditingController controller;
  final bool isEditable;

  EditorTextArea({
    required this.controller,
    required this.isEditable,
  }) : super(
    // When the example is changed, will scroll to the context line again.
    key: ValueKey(controller.selectedExample),
  );

  @override
  State<EditorTextArea> createState() => _EditorTextAreaState();
}

class _EditorTextAreaState extends State<EditorTextArea> {
  bool _didAutoFocus = false;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _sizeKey = LabeledGlobalKey('CodeFieldKey');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didAutoFocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollSoCursorIsOnTop();
        }
      });
    }
  }

  void _scrollSoCursorIsOnTop() {
    _focusNode.requestFocus();

    final position = max(widget.controller.codeController.selection.start, 0);
    final characterOffset = _getLastCharacterOffset(
      text: widget.controller.codeController.text.substring(0, position),
      style: kLightTheme.extension<BeamThemeExtension>()!.codeRootStyle,
    );

    _scrollController.jumpTo(
      min(
        characterOffset.dy,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<BeamThemeExtension>()!;
    final isMultifile = widget.controller.selectedExample?.isMultiFile ?? false;
    final isEnabled = widget.isEditable && !isMultifile;

    return Semantics(
      container: true,
      textField: true,
      multiline: true,
      enabled: isEnabled,
      readOnly: isEnabled,
      label: 'widgets.codeEditor.label',
      child: FocusScope(
        key: _sizeKey,
        node: FocusScopeNode(canRequestFocus: isEnabled),
        child: CodeTheme(
          data: ext.codeTheme,
          child: Container(
            color: ext.codeTheme.styles['root']?.backgroundColor,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: CodeField(
                key: ValueKey(widget.controller.codeController),
                focusNode: _focusNode,
                enabled: isEnabled,
                controller: widget.controller.codeController,
                textStyle: ext.codeRootStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Offset _getLastCharacterOffset({
  required String text,
  required TextStyle style,
}) {
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(text: text, style: style),
  )..layout();

  return textPainter.getOffsetForCaret(
    TextPosition(offset: text.length),
    Rect.zero,
  );
}
