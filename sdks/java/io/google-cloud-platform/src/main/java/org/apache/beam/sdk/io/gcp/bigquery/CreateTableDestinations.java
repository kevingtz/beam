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
package org.apache.beam.sdk.io.gcp.bigquery;

import static org.apache.beam.vendor.guava.v26_0_jre.com.google.common.base.Preconditions.checkArgument;

import com.google.api.services.bigquery.model.TableSchema;
import java.util.List;
import java.util.Map;
import javax.annotation.Nullable;
import org.apache.beam.sdk.coders.Coder;
import org.apache.beam.sdk.io.gcp.bigquery.BigQueryIO.Write.CreateDisposition;
import org.apache.beam.sdk.transforms.DoFn;
import org.apache.beam.sdk.transforms.PTransform;
import org.apache.beam.sdk.transforms.ParDo;
import org.apache.beam.sdk.values.KV;
import org.apache.beam.sdk.values.PCollection;
import org.apache.beam.sdk.values.PCollectionView;
import org.apache.beam.vendor.guava.v26_0_jre.com.google.common.base.Supplier;
import org.apache.beam.vendor.guava.v26_0_jre.com.google.common.collect.Lists;
import org.apache.beam.vendor.guava.v26_0_jre.com.google.common.collect.Maps;

/**
 * Creates any tables needed before performing writes to the tables. This is a side-effect {@link
 * DoFn}, and returns the original collection unchanged.
 */
public class CreateTableDestinations<DestinationT, ElementT>
    extends PTransform<
        PCollection<KV<DestinationT, ElementT>>, PCollection<KV<DestinationT, ElementT>>> {
  private final CreateDisposition createDisposition;
  private final BigQueryServices bqServices;
  private final DynamicDestinations<?, DestinationT> dynamicDestinations;
  @Nullable private final String kmsKey;

  public CreateTableDestinations(
      CreateDisposition createDisposition,
      DynamicDestinations<?, DestinationT> dynamicDestinations) {
    this(createDisposition, new BigQueryServicesImpl(), dynamicDestinations, null);
  }

  public CreateTableDestinations(
      CreateDisposition createDisposition,
      BigQueryServices bqServices,
      DynamicDestinations<?, DestinationT> dynamicDestinations,
      @Nullable String kmsKey) {
    this.createDisposition = createDisposition;
    this.bqServices = bqServices;
    this.dynamicDestinations = dynamicDestinations;
    this.kmsKey = kmsKey;
  }

  CreateTableDestinations<DestinationT, ElementT> withKmsKey(String kmsKey) {
    return new CreateTableDestinations<>(
        createDisposition, bqServices, dynamicDestinations, kmsKey);
  }

  CreateTableDestinations<DestinationT, ElementT> withTestServices(BigQueryServices bqServices) {
    return new CreateTableDestinations<>(
        createDisposition, bqServices, dynamicDestinations, kmsKey);
  }

  @Override
  public PCollection<KV<DestinationT, ElementT>> expand(
      PCollection<KV<DestinationT, ElementT>> input) {
    List<PCollectionView<?>> sideInputs = Lists.newArrayList();
    sideInputs.addAll(dynamicDestinations.getSideInputs());

    return input.apply("CreateTables", ParDo.of(new CreateTablesFn()).withSideInputs(sideInputs));
  }

  private class CreateTablesFn
      extends DoFn<KV<DestinationT, ElementT>, KV<DestinationT, ElementT>> {
    private Map<DestinationT, TableDestination> destinations = Maps.newHashMap();

    @StartBundle
    public void startBundle() {
      destinations = Maps.newHashMap();
    }

    @ProcessElement
    public void processElement(
        ProcessContext context,
        @Element KV<DestinationT, ElementT> element,
        OutputReceiver<KV<DestinationT, ElementT>> o) {
      dynamicDestinations.setSideInputAccessorFromProcessContext(context);
      destinations.computeIfAbsent(
          element.getKey(),
          dest -> {
            @Nullable TableDestination tableDestination1 = dynamicDestinations.getTable(dest);
            checkArgument(
                tableDestination1 != null,
                "DynamicDestinations.getTable() may not return null, "
                    + "but %s returned null for destination %s",
                dynamicDestinations,
                dest);
            @Nullable
            Coder<DestinationT> destinationCoder = dynamicDestinations.getDestinationCoder();
            Supplier<TableSchema> schemaSupplier = () -> dynamicDestinations.getSchema(dest);
            return CreateTableHelpers.possiblyCreateTable(
                context,
                tableDestination1,
                schemaSupplier,
                createDisposition,
                destinationCoder,
                kmsKey,
                bqServices);
          });

      o.output(element);
    }
  }
}
