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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:playground_components/playground_components.dart';
import 'package:playground_components_dev/playground_components_dev.dart';
import 'package:tour_of_beam/cache/content_tree.dart';
import 'package:tour_of_beam/components/builders/content_tree.dart';
import 'package:tour_of_beam/models/group.dart';
import 'package:tour_of_beam/models/module.dart';
import 'package:tour_of_beam/models/unit.dart';
import 'package:tour_of_beam/pages/tour/screen.dart';
import 'package:tour_of_beam/pages/tour/widgets/unit.dart';
import 'package:tour_of_beam/pages/tour/widgets/unit_content.dart';

import 'common/common.dart';
import 'common/common_finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'ToB miscellaneous ui',
    (wt) async {
      await init(wt);
      await wt.tapAndSettle(find.text(Sdk.java.title));
      await wt.tapAndSettle(find.startTourButton());

      await _checkContentTreeBuildsProperly(wt);
      await _checkUnitContentLoadsProperly(wt);
      await _checkContentTreeScrollsProperly(wt);
      await _checkDisplayingSelectedUnit(wt);
      await _checkRunCodeWorks(wt);
      await _checkResizeUnitContent(wt);
    },
  );
}

Future<void> _checkContentTreeBuildsProperly(WidgetTester wt) async {
  final modules = _getModules(wt);

  for (final module in modules) {
    await _checkModule(module, wt);
  }
}

List<ModuleModel> _getModules(WidgetTester wt) {
  final contentTreeCache = GetIt.instance.get<ContentTreeCache>();
  final controller = getContentTreeController(wt);
  final contentTree = contentTreeCache.getContentTree(controller.sdkId);
  return contentTree?.modules ?? [];
}

Future<void> _checkModule(ModuleModel module, WidgetTester wt) async {
  for (final node in module.nodes) {
    if (node is UnitModel) {
      expect(
        find.descendant(
          of: find.byType(ContentTreeBuilder),
          matching: find.text(node.title),
        ),
        findsAtLeastNWidgets(1),
      );
    }
    if (node is GroupModel) {
      await _checkGroup(node, wt);
    }
  }
}

Future<void> _checkGroup(GroupModel group, WidgetTester wt) async {
  final contentTreeController = getContentTreeController(wt);
  contentTreeController.expandGroup(group);
  await wt.pumpAndSettle();
  for (final node in group.nodes) {
    expect(
      find.descendant(
        of: find.byType(ContentTreeBuilder),
        matching: find.text(node.title),
      ),
      findsAtLeastNWidgets(1),
    );
  }
}

Future<void> _checkUnitContentLoadsProperly(WidgetTester wt) async {
  final modules = _getModules(wt);

  final unit = modules.expand((m) => m.nodes).whereType<UnitModel>().first;

  await wt.tapAndSettle(
    find.descendant(
      of: find.byType(UnitWidget),
      matching: find.text(unit.title),
    ),
  );

  expect(
    find.descendant(
      of: find.byType(UnitContentWidget),
      matching: find.text(unit.title),
    ),
    findsOneWidget,
  );
}

Future<void> _checkContentTreeScrollsProperly(WidgetTester wt) async {
  final modules = _getModules(wt);
  final lastNode = modules.expand((m) => m.nodes).whereType<UnitModel>().last;

  await wt.ensureVisible(
    find.descendant(
      of: find.byType(UnitWidget),
      matching: find.text(lastNode.title),
      skipOffstage: false,
    ),
  );
  await wt.pumpAndSettle();
}

Future<void> _checkDisplayingSelectedUnit(WidgetTester wt) async {
  final controller = getContentTreeController(wt);
  final selectedUnit = controller.currentNode;

  if (selectedUnit == null) {
    return;
  }

  final selectedUnitText = find.descendant(
    of: find.byType(UnitWidget),
    matching: find.text(selectedUnit.title),
    skipOffstage: false,
  );

  final selectedUnitContainer = find.ancestor(
    of: selectedUnitText,
    matching: find.byKey(UnitWidget.containerKey),
  );

  final context = wt.element(selectedUnitContainer);

  expect(
    (wt.widget<Container>(selectedUnitContainer).decoration as BoxDecoration?)
        ?.color,
    Theme.of(context).selectedRowColor,
  );
}

Future<void> _checkResizeUnitContent(WidgetTester wt) async {
  var dragHandleFinder = find.byKey(TourScreen.dragHandleKey);

  final startHandlePosition = wt.getCenter(dragHandleFinder);

  await wt.drag(dragHandleFinder, const Offset(100, 0));
  await wt.pumpAndSettle();

  dragHandleFinder = find.byKey(TourScreen.dragHandleKey);

  final movedHandlePosition = wt.getCenter(dragHandleFinder);

  expectSimilar(startHandlePosition.dx, movedHandlePosition.dx - 100);
}

Future<void> _checkRunCodeWorks(WidgetTester wt) async {
  const text = 'OK';
  const code = '''
public class MyClass {
  public static void main(String[] args) {
    System.out.print("$text");
  }
}
''';

  await wt.enterText(find.codeField(), code);
  await wt.pumpAndSettle();

  await _runAndCancelExample(wt, const Duration(milliseconds: 300));

  await wt.tapAndSettle(find.runOrCancelButton());

  final playgroundController = _getPlaygroundController(wt);
  expect(
    playgroundController.codeRunner.resultLogOutput,
    contains(text),
  );
}

Future<void> _runAndCancelExample(WidgetTester wt, Duration duration) async {
  await wt.tap(find.runOrCancelButton());

  await wt.pumpAndSettleNoException(timeout: duration);
  await wt.tapAndSettle(find.runOrCancelButton());

  final playgroundController = _getPlaygroundController(wt);
  expect(
    playgroundController.codeRunner.resultLogOutput,
    contains('Pipeline cancelled'),
  );
}

PlaygroundController _getPlaygroundController(WidgetTester wt) {
  return (wt.widget(find.byType(UnitContentWidget)) as UnitContentWidget)
      .tourNotifier
      .playgroundController;
}
