#   Licensed to the Apache Software Foundation (ASF) under one
#   or more contributor license agreements.  See the NOTICE file
#   distributed with this work for additional information
#   regarding copyright ownership.  The ASF licenses this file
#   to you under the Apache License, Version 2.0 (the
#   "License"); you may not use this file except in compliance
#   with the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# beam-playground:
#   name: branching
#   description: Branching example.
#   multifile: false
#   context_line: 42

import apache_beam as beam

# Output PCollection
class Output(beam.PTransform):
    class _OutputFn(beam.DoFn):
        def __init__(self, prefix=''):
            super().__init__()
            self.prefix = prefix

        def process(self, element):
            print(self.prefix+str(element))

    def __init__(self, label=None,prefix=''):
        super().__init__(label)
        self.prefix = prefix

    def expand(self, input):
        input | beam.ParDo(self._OutputFn(self.prefix))

with beam.Pipeline() as p:

    # List of elements
    numbers = p | beam.Create([1, 2, 3, 4, 5])

    # Return PCollection with elements multiplied by 5
    mult5_results = numbers | beam.Map(lambda num: num * 5)

    # Return PCollection with elements multiplied by 10
    mult10_results = numbers | beam.Map(lambda num: num * 10)

    mult5_results | 'Log multiply 5' >> Output(prefix='Multiplied by 5: ')
    mult10_results | 'Log multiply 10' >> Output(prefix='Multiplied by 10: ')