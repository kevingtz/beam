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

import 'package:flutter_test/flutter_test.dart';
import 'package:playground/modules/examples/models/example_loading_descriptors/content_example_loading_descriptor.dart';
import 'package:playground/modules/examples/models/example_loading_descriptors/empty_example_loading_descriptor.dart';
import 'package:playground/modules/examples/models/example_loading_descriptors/examples_loading_descriptor.dart';
import 'package:playground/modules/messages/models/set_content_message.dart';
import 'package:playground/modules/sdk/models/sdk.dart';

const _content = 'my_code';
const _sdk = SDK.python;

void main() {
  group('SetContentMessage.tryParse', () {
    test(
      'returns null for other types',
      () {
        const map = {'type': 'any-other'};

        final parsed = SetContentMessage.tryParse(map);

        expect(parsed, null);
      },
    );

    test(
      'parses an empty message without descriptor',
      () {
        const map = {'type': SetContentMessage.type};

        final parsed = SetContentMessage.tryParse(map);

        expect(
          parsed,
          const SetContentMessage(
            descriptor: ExamplesLoadingDescriptor(
              descriptors: [EmptyExampleLoadingDescriptor(sdk: SDK.java)],
            ),
          ),
        );
      },
    );

    test(
      'parses an empty message with an invalid descriptor',
      () {
        const map = {
          'type': SetContentMessage.type,
          'descriptor': 123,
        };

        final parsed = SetContentMessage.tryParse(map);

        expect(
          parsed,
          const SetContentMessage(
            descriptor: ExamplesLoadingDescriptor(
              descriptors: [EmptyExampleLoadingDescriptor(sdk: SDK.java)],
            ),
          ),
        );
      },
    );

    test(
      'parses messages',
      () {
        final map = {
          'type': SetContentMessage.type,
          'descriptor': {
            'descriptors': [
              null,
              1,
              1.0,
              'string',
              [],
              {'type': 'any-other'},
              {
                'content': _content,
                'name': 'name',
                'sdk': _sdk.name,
              },
              {
                'content': _content,
                'name': null,
                'sdk': _sdk.name,
              },
              {
                'content': _content,
                'sdk': _sdk.name,
              },
            ],
          },
        };

        final parsed = SetContentMessage.tryParse(map);

        expect(
          parsed,
          const SetContentMessage(
            descriptor: ExamplesLoadingDescriptor(
              descriptors: [
                ContentExampleLoadingDescriptor(
                  content: _content,
                  name: 'name',
                  sdk: _sdk,
                ),
                ContentExampleLoadingDescriptor(
                  content: _content,
                  name: null,
                  sdk: _sdk,
                ),
                ContentExampleLoadingDescriptor(
                  content: _content,
                  name: null,
                  sdk: _sdk,
                ),
              ],
            ),
          ),
        );
      },
    );
  });
}
