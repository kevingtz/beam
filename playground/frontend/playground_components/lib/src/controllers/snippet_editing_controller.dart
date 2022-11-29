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

import 'package:flutter/widgets.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../models/example.dart';
import '../models/example_loading_descriptors/content_example_loading_descriptor.dart';
import '../models/example_loading_descriptors/empty_example_loading_descriptor.dart';
import '../models/example_loading_descriptors/example_loading_descriptor.dart';
import '../models/example_view_options.dart';
import '../models/sdk.dart';

class SnippetEditingController extends ChangeNotifier {
  final Sdk sdk;
  final CodeController codeController;
  Example? _selectedExample;
  String _pipelineOptions = '';

  SnippetEditingController({
    required this.sdk,
  }) : codeController = CodeController(
          language: sdk.highlightMode,
          namedSectionParser: const BracketsStartEndNamedSectionParser(),
          webSpaceFix: false,
        );

  set selectedExample(Example? value) {
    _selectedExample = value;
    setSource(_selectedExample?.source ?? '');

    final viewOptions = value?.viewOptions;
    if (viewOptions != null) {
      _applyViewOptions(viewOptions);
    }

    _pipelineOptions = _selectedExample?.pipelineOptions ?? '';
    notifyListeners();
  }

  void _applyViewOptions(ExampleViewOptions options) {
    codeController.readOnlySectionNames = options.readOnlySectionNames.toSet();
    codeController.visibleSectionNames = options.showSectionNames.toSet();

    if (options.foldCommentAtLineZero) {
      codeController.foldCommentAtLineZero();
    }

    if (options.foldImports) {
      codeController.foldImports();
    }

    final unfolded = options.unfoldSectionNames;
    if (unfolded.isNotEmpty) {
      codeController.foldOutsideSections(unfolded);
    }
  }

  Example? get selectedExample => _selectedExample;

  set pipelineOptions(String value) {
    _pipelineOptions = value;
    notifyListeners();
  }

  String get pipelineOptions => _pipelineOptions;

  bool get isChanged {
    return _isCodeChanged() || _arePipelineOptionsChanged();
  }

  bool _isCodeChanged() {
    return _selectedExample?.source != codeController.fullText;
  }

  bool _arePipelineOptionsChanged() {
    return _pipelineOptions != (_selectedExample?.pipelineOptions ?? '');
  }

  void reset() {
    codeController.text = _selectedExample?.source ?? '';
    _pipelineOptions = _selectedExample?.pipelineOptions ?? '';
  }

  /// Creates an [ExampleLoadingDescriptor] that can recover the
  /// current content.
  ExampleLoadingDescriptor getLoadingDescriptor() {
    final example = selectedExample;
    if (example == null) {
      return EmptyExampleLoadingDescriptor(sdk: sdk);
    }

    if (!isChanged) {
      return example.descriptor;
    }
    
    return ContentExampleLoadingDescriptor(
      complexity: example.complexity,
      content: codeController.fullText,
      name: example.name,
      sdk: sdk,
    );
  }

  void setSource(String source) {
    codeController.readOnlySectionNames = const {};
    codeController.visibleSectionNames = const {};

    codeController.fullText = source;
    codeController.historyController.deleteHistory();
  }
}
