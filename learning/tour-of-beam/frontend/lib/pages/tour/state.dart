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

import 'package:app_state/app_state.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:playground_components/playground_components.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../../auth/notifier.dart';
import '../../cache/unit_content.dart';
import '../../cache/unit_progress.dart';
import '../../config.dart';
import '../../enums/save_code_status.dart';
import '../../enums/snippet_type.dart';
import '../../models/unit.dart';
import '../../models/unit_content.dart';
import '../../state.dart';
import 'controllers/content_tree.dart';
import 'path.dart';

class TourNotifier extends ChangeNotifier with PageStateMixin<void> {
  static const _saveUserCodeDebounceDuration = Duration(seconds: 2);
  Debounce? _saveCodeDebounced;

  final ContentTreeController contentTreeController;
  final PlaygroundController playgroundController;
  final _appNotifier = GetIt.instance.get<AppNotifier>();
  final _authNotifier = GetIt.instance.get<AuthNotifier>();
  final _unitContentCache = GetIt.instance.get<UnitContentCache>();
  final _unitProgressCache = GetIt.instance.get<UnitProgressCache>();
  UnitContentModel? _currentUnitContent;

  TourNotifier({
    required String initialSdkId,
    List<String> initialTreeIds = const [],
  })  : contentTreeController = ContentTreeController(
          initialSdkId: initialSdkId,
          initialTreeIds: initialTreeIds,
        ),
        playgroundController = _createPlaygroundController(initialSdkId) {
    _appNotifier.sdkId ??= initialSdkId;
    contentTreeController.addListener(_onUnitChanged);
    _unitContentCache.addListener(_onUnitChanged);
    _appNotifier.addListener(_onAppNotifierChanged);
    _authNotifier.addListener(_onAuthChanged);
    _saveCodeDebounced = _saveCode.debounced(
      _saveUserCodeDebounceDuration,
    );
    // setSdk creates snippetEditingController if it doesn't exist.
    playgroundController.setSdk(currentSdk);
    _listenToCurrentSnippetEditingController();
    unawaited(_onUnitChanged());
  }

  @override
  void setStateMap(Map<String, dynamic> state) {
    super.setStateMap(state);
    _appNotifier.sdkId = state['sdkId'];
  }

  @override
  PagePath get path => TourPath(
        sdkId: contentTreeController.sdkId,
        treeIds: contentTreeController.treeIds,
      );

  bool get isAuthenticated => _authNotifier.isAuthenticated;

  Sdk get currentSdk => _appNotifier.sdk!;
  String? get currentUnitId => _currentUnitContent?.id;
  UnitContentModel? get currentUnitContent => _currentUnitContent;

  bool get hasSolution => currentUnitContent?.solutionSnippetId != null;
  bool get isCodeSaved => _unitProgressCache.hasSavedSnippet(currentUnitId);

  SnippetType _snippetType = SnippetType.original;
  SnippetType get snippetType => _snippetType;

  SaveCodeStatus _saveCodeStatus = SaveCodeStatus.saved;
  SaveCodeStatus get saveCodeStatus => _saveCodeStatus;
  set saveCodeStatus(SaveCodeStatus saveCodeStatus) {
    _saveCodeStatus = saveCodeStatus;
    notifyListeners();
  }

  Future<void> _onAuthChanged() async {
    await _unitProgressCache.loadUnitProgress(currentSdk);
    // The local changes are preserved if the user signs in.
    if (_snippetType != SnippetType.saved || !isAuthenticated) {
      await _loadSnippetByType();
    }
    notifyListeners();
  }

  Future<void> _onAppNotifierChanged() async {
    contentTreeController.sdkId = currentSdk.id;
    playgroundController.setSdk(currentSdk);
    _listenToCurrentSnippetEditingController();

    await _unitProgressCache.loadUnitProgress(currentSdk);
    _trySetSnippetType(SnippetType.saved);
    await _loadSnippetByType();
  }

  Future<void> _onUnitChanged() async {
    emitPathChanged();
    final currentNode = contentTreeController.currentNode;
    if (currentNode is! UnitModel) {
      await _emptyPlayground();
    } else {
      final sdk = contentTreeController.sdk;
      final content = await _unitContentCache.getUnitContent(
        sdk.id,
        currentNode.id,
      );
      _setUnitContent(content);
      await _unitProgressCache.loadUnitProgress(currentSdk);
      _trySetSnippetType(SnippetType.saved);
      await _loadSnippetByType();
    }
    notifyListeners();
  }

  void _setUnitContent(UnitContentModel? unitContent) {
    if (unitContent == null || unitContent == _currentUnitContent) {
      return;
    }
    _currentUnitContent = unitContent;
  }

  // Save user code.

  Future<void> showSnippetByType(SnippetType snippetType) async {
    _trySetSnippetType(snippetType);
    await _loadSnippetByType();
    notifyListeners();
  }

  void _listenToCurrentSnippetEditingController() {
    playgroundController.snippetEditingController?.addListener(
      _onActiveFileControllerChanged,
    );
  }

  void _onActiveFileControllerChanged() {
    playgroundController
        .snippetEditingController?.activeFileController?.codeController
        .addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final snippetEditingController =
        playgroundController.snippetEditingController!;
    final isCodeChanged =
        snippetEditingController.activeFileController?.isChanged ?? false;
    final snippetFiles = snippetEditingController.getFiles();

    final doSave = _isSnippetTypeSavable() &&
        isCodeChanged &&
        _currentUnitContent != null &&
        snippetFiles.isNotEmpty;

    if (doSave) {
      // Snapshot of sdk and unitId at the moment of editing.
      final sdk = currentSdk;
      final unitId = currentUnitId;
      _saveCodeDebounced?.call([], {
        const Symbol('sdk'): sdk,
        const Symbol('snippetFiles'): snippetFiles,
        const Symbol('unitId'): unitId,
      });
    }
  }

  bool _isSnippetTypeSavable() {
    return snippetType != SnippetType.solution;
  }

  Future<void> _saveCode({
    required Sdk sdk,
    required List<SnippetFile> snippetFiles,
    required String unitId,
  }) async {
    saveCodeStatus = SaveCodeStatus.saving;
    try {
      await _unitProgressCache.saveSnippet(
        sdk: sdk,
        snippetFiles: snippetFiles,
        snippetType: _snippetType,
        unitId: unitId,
      );
      saveCodeStatus = SaveCodeStatus.saved;
      await _unitProgressCache.loadUnitProgress(currentSdk);
      _trySetSnippetType(SnippetType.saved);
    } on Exception catch (e) {
      print(['Could not save code: ', e]);
      _saveCodeStatus = SaveCodeStatus.error;
    }
  }

  void _trySetSnippetType(SnippetType snippetType) {
    if (snippetType == SnippetType.saved && !isCodeSaved) {
      _snippetType = SnippetType.original;
    } else {
      _snippetType = snippetType;
    }
    notifyListeners();
  }

  Future<void> _loadSnippetByType() async {
    final ExampleLoadingDescriptor descriptor;
    switch (_snippetType) {
      case SnippetType.original:
        descriptor = _getStandardOrEmptyDescriptor(
          currentSdk,
          _currentUnitContent!.taskSnippetId,
        );
        break;
      case SnippetType.saved:
        descriptor = await _unitProgressCache.getSavedDescriptor(
          sdk: currentSdk,
          unitId: _currentUnitContent!.id,
        );
        break;
      case SnippetType.solution:
        descriptor = _getStandardOrEmptyDescriptor(
          currentSdk,
          _currentUnitContent!.solutionSnippetId,
        );
        break;
    }
    await playgroundController.examplesLoader.load(
      ExamplesLoadingDescriptor(
        descriptors: [
          descriptor,
        ],
      ),
    );
  }

  ExampleLoadingDescriptor _getStandardOrEmptyDescriptor(
    Sdk sdk,
    String? snippetId,
  ) {
    if (snippetId == null) {
      return EmptyExampleLoadingDescriptor(
        sdk: currentSdk,
      );
    }
    return StandardExampleLoadingDescriptor(
      path: snippetId,
      sdk: sdk,
    );
  }

  // TODO(alexeyinkin): Hide the entire right pane instead.
  Future<void> _emptyPlayground() async {
    await playgroundController.examplesLoader.loadIfNew(
      ExamplesLoadingDescriptor(
        descriptors: [
          EmptyExampleLoadingDescriptor(sdk: contentTreeController.sdk),
        ],
      ),
    );
  }

  // Playground controller.

  static PlaygroundController _createPlaygroundController(String initialSdkId) {
    final exampleRepository = ExampleRepository(
      client: GrpcExampleClient(url: kApiClientURL),
    );

    final codeRepository = CodeRepository(
      client: GrpcCodeClient(
        url: kApiClientURL,
        runnerUrlsById: {
          Sdk.java.id: kApiJavaClientURL,
          Sdk.go.id: kApiGoClientURL,
          Sdk.python.id: kApiPythonClientURL,
          Sdk.scio.id: kApiScioClientURL,
        },
      ),
    );

    final exampleCache = ExampleCache(
      exampleRepository: exampleRepository,
    );

    final playgroundController = PlaygroundController(
      codeRepository: codeRepository,
      exampleCache: exampleCache,
      examplesLoader: ExamplesLoader(),
    );

    unawaited(
      playgroundController.examplesLoader.loadIfNew(
        ExamplesLoadingDescriptor(
          descriptors: [
            EmptyExampleLoadingDescriptor(sdk: Sdk.parseOrCreate(initialSdkId)),
          ],
        ),
      ),
    );

    return playgroundController;
  }

  @override
  Future<void> dispose() async {
    _unitContentCache.removeListener(_onUnitChanged);
    contentTreeController.removeListener(_onUnitChanged);
    _appNotifier.removeListener(_onAppNotifierChanged);
    _authNotifier.removeListener(_onAuthChanged);
    playgroundController.snippetEditingController
        ?.removeListener(_onActiveFileControllerChanged);
    // TODO(nausharipov): Use stream events https://github.com/apache/beam/issues/25185
    playgroundController
        .snippetEditingController?.activeFileController?.codeController
        .removeListener(_onCodeChanged);
    await super.dispose();
  }
}
