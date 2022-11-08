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
#   name: partition
#   description: Partition example.
#   multifile: false
#   context_line: 49

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

def partition_fn(number, num_partitions):
    if number > 100:
        return 0
    else:
        return 1


with beam.Pipeline() as p:

  results = \
        (p | beam.Create([1, 2, 3, 4, 5, 100, 110, 150, 250])
        # Accepts PCollection and returns the PCollection array
         | beam.Partition(partition_fn, 2))

  results[0] | 'Log numbers > 100' >> Output(prefix='Number > 100: ')
  results[1] | 'Log numbers <= 100' >> Output(prefix='Number <= 100: ')