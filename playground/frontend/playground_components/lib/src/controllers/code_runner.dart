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

import 'dart:async';

import 'package:flutter/material.dart';

import '../../playground_components.dart';
import '../enums/unread_entry.dart';
import '../repositories/models/run_code_request.dart';
import '../repositories/models/run_code_result.dart';
import 'snippet_editing_controller.dart';
import 'unread_controller.dart';

class CodeRunner extends ChangeNotifier {
  final CodeRepository? _codeRepository;
  final ValueGetter<SnippetEditingController> _snippetEditingControllerGetter;
  SnippetEditingController? snippetEditingController;
  final unreadController = UnreadController();

  CodeRunner({
    required ValueGetter<SnippetEditingController>
        snippetEditingControllerGetter,
    CodeRepository? codeRepository,
  })  : _codeRepository = codeRepository,
        _snippetEditingControllerGetter = snippetEditingControllerGetter;

  RunCodeResult? _result;
  StreamSubscription<RunCodeResult>? _runSubscription;
  DateTime? _runStartDate;
  DateTime? _runStopDate;

  String? get pipelineOptions =>
      _snippetEditingControllerGetter().pipelineOptions;

  RunCodeResult? get result => _result;

  DateTime? get runStartDate => _runStartDate;

  DateTime? get runStopDate => _runStopDate;

  bool get isCodeRunning => !(_result?.isFinished ?? true);

  String get resultLog => _result?.log ?? '';

  String get resultOutput => _result?.output ?? '';

  String get resultLogOutput => resultLog + resultOutput;

  bool get isExampleChanged {
    return _snippetEditingControllerGetter().isChanged;
  }

  void clearResult() {
    _setResult(null);
    notifyListeners();
  }

  void runCode({void Function()? onFinish}) {
    _runStartDate = DateTime.now();
    _runStopDate = null;
    notifyListeners();
    snippetEditingController = _snippetEditingControllerGetter();
    final sdk = snippetEditingController!.sdk;

    final parsedPipelineOptions =
        parsePipelineOptions(snippetEditingController!.pipelineOptions);
    if (parsedPipelineOptions == null) {
      _setResult(
        RunCodeResult(
          errorMessage: kPipelineOptionsParseError,
          sdk: sdk,
          status: RunCodeStatus.compileError,
        ),
      );
      _runStopDate = DateTime.now();
      notifyListeners();
      return;
    }

    if (!isExampleChanged &&
        snippetEditingController!.example?.outputs != null) {
      unawaited(_showPrecompiledResult());
    } else {
      final request = RunCodeRequest(
        datasets: snippetEditingController?.example?.datasets ?? [],
        files: snippetEditingController!.getFiles(),
        sdk: snippetEditingController!.sdk,
        pipelineOptions: parsedPipelineOptions,
      );
      _runSubscription = _codeRepository?.runCode(request).listen((event) {
        _setResult(event);
        notifyListeners();

        if (event.isFinished) {
          if (onFinish != null) {
            onFinish();
          }
          snippetEditingController = null;
          _runStopDate = DateTime.now();
        }
      });
      notifyListeners();
    }
  }

  /// Resets the error message text so that on the next rebuild
  /// of `CodeTextAreaWrapper` it is not picked up and not shown as a toast.
  // TODO: Listen to this object outside of widgets,
  //  emit toasts from notifications, then remove this method.
  void resetErrorMessageText() {
    if (_result == null) {
      return;
    }

    _setResult(
      RunCodeResult(
        output: _result!.output,
        sdk: _result!.sdk,
        status: _result!.status,
      ),
    );

    notifyListeners();
  }

  Future<void> cancelRun() async {
    final sdk = _result?.sdk;
    if (sdk == null) {
      return;
    }

    snippetEditingController = null;
    await _runSubscription?.cancel();
    final pipelineUuid = _result?.pipelineUuid ?? '';

    if (pipelineUuid.isNotEmpty) {
      await _codeRepository?.cancelExecution(pipelineUuid);
    }

    _setResult(
      RunCodeResult(
        graph: _result?.graph,
        log: (_result?.log ?? '') + kExecutionCancelledText,
        output: _result?.output,
        sdk: sdk,
        status: RunCodeStatus.finished,
      ),
    );

    _runStopDate = DateTime.now();
    notifyListeners();
  }

  Future<void> _showPrecompiledResult() async {
    final selectedExample = snippetEditingController!.example!;

    _setResult(
      RunCodeResult(
        sdk: selectedExample.sdk,
        status: RunCodeStatus.preparation,
      ),
    );

    notifyListeners();
    // add a little delay to improve user experience
    await Future.delayed(kPrecompiledDelay);

    final String logs = selectedExample.logs ?? '';
    _setResult(
      RunCodeResult(
        graph: selectedExample.graph,
        log: kCachedResultsLog + logs,
        output: selectedExample.outputs,
        sdk: selectedExample.sdk,
        status: RunCodeStatus.finished,
      ),
    );

    _runStopDate = DateTime.now();
    notifyListeners();
  }

  void _setResult(RunCodeResult? newValue) {
    _result = newValue;

    if (newValue == null) {
      unreadController.markAllRead();
    } else {
      unreadController.setValue(
        UnreadEntryEnum.result,
        (newValue.output ?? '') + (newValue.log ?? ''),
      );
      unreadController.setValue(
        UnreadEntryEnum.graph,
        newValue.graph ?? '',
      );
    }
  }
}
