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

import '../repositories/models/get_content_tree_response.dart';
import 'module.dart';
import 'node.dart';
import 'parent_node.dart';
import 'unit.dart';

class ContentTreeModel extends ParentNodeModel {
  final List<ModuleModel> modules;

  final List<UnitModel> units;

  String get sdkId => id;

  const ContentTreeModel({
    required super.id,
    required this.modules,
    required this.units,
  }) : super(
          parent: null,
          title: '',
          nodes: modules,
        );

  static List<UnitModel> _getUnitsFromModules(List<ModuleModel> modules) {
    final units = <UnitModel>[];

    void extractUnitsFromNode(NodeModel node) {
      if (node is ParentNodeModel) {
        node.nodes.forEach(extractUnitsFromNode);
      } else if (node is UnitModel) {
        units.add(node);
      }
    }

    modules.forEach(extractUnitsFromNode);
    return units;
  }

  ContentTreeModel.fromResponse(GetContentTreeResponse response)
      : this(
          id: response.sdkId,
          modules: response.modules
              .map(ModuleModel.fromResponse)
              .toList(growable: false),
          units: _getUnitsFromModules(
            response.modules
                .map(ModuleModel.fromResponse)
                .toList(growable: false),
          ),
        );
}
