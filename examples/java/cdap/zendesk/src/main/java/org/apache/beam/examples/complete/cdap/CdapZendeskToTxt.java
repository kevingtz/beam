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
package org.apache.beam.examples.complete.cdap;

import static org.apache.beam.examples.complete.cdap.transforms.FormatInputTransform.readFromCdapZendesk;

import io.cdap.cdap.api.data.format.StructuredRecord;
import java.util.Map;
import org.apache.beam.examples.complete.cdap.options.CdapZendeskOptions;
import org.apache.beam.examples.complete.cdap.utils.PluginConfigOptionsConverter;
import org.apache.beam.examples.complete.cdap.utils.StructuredRecordUtils;
import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.PipelineResult;
import org.apache.beam.sdk.coders.KvCoder;
import org.apache.beam.sdk.coders.NullableCoder;
import org.apache.beam.sdk.coders.SerializableCoder;
import org.apache.beam.sdk.coders.StringUtf8Coder;
import org.apache.beam.sdk.io.TextIO;
import org.apache.beam.sdk.io.hadoop.WritableCoder;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.transforms.MapValues;
import org.apache.beam.sdk.transforms.Values;
import org.apache.beam.sdk.values.TypeDescriptors;
import org.apache.hadoop.io.NullWritable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The {@link CdapZendeskToTxt} pipeline is a batch pipeline which ingests data in JSON format from
 * CDAP Zendesk, and outputs the resulting records to .txt file. Zendesk parameters and output txt
 * file path are specified by the user as template parameters. <br>
 *
 * <p><b>Example Usage</b>
 *
 * <pre>
 * # Gradle preparation
 *
 * To run this example your {@code build.gradle} file should contain the following task
 * to execute the pipeline:
 * {@code
 * task executeCdap (type:JavaExec) {
 *     mainClass = System.getProperty("mainClass")
 *     classpath = sourceSets.main.runtimeClasspath
 *     systemProperties System.getProperties()
 *     args System.getProperty("exec.args", "").split()
 * }
 * }
 *
 * This task allows to run the pipeline via the following command:
 * {@code
 * gradle clean executeCdap -DmainClass=org.apache.beam.examples.complete.cdap.zendesk.CdapZendeskToTxt \
 *      -Dexec.args="--<argument>=<value> --<argument>=<value>"
 * }
 *
 * # Running the pipeline
 * To execute this pipeline, specify the parameters in the following format:
 * {@code
 * --zendeskBaseUrl=your-url \
 * --adminEmail=your-email \
 * --apiToken=your-token \
 * --objectsToPull=Groups \
 * --referenceName=your-reference-name \
 * --outputTxtFilePathPrefix=your-path-to-output-folder-with-filename-prefix
 * }
 *
 * By default this will run the pipeline locally with the DirectRunner. To change the runner, specify:
 * {@code
 * --runner=YOUR_SELECTED_RUNNER
 * }
 * </pre>
 */
public class CdapZendeskToTxt {

  /* Logger for class.*/
  private static final Logger LOG = LoggerFactory.getLogger(CdapZendeskToTxt.class);

  /**
   * Main entry point for pipeline execution.
   *
   * @param args Command line arguments to the pipeline.
   */
  public static void main(String[] args) {
    CdapZendeskOptions options =
        PipelineOptionsFactory.fromArgs(args).withValidation().as(CdapZendeskOptions.class);

    // Create the pipeline
    Pipeline pipeline = Pipeline.create(options);
    run(pipeline, options);
  }

  /**
   * Runs a pipeline which reads message from CDAP and writes it to .txt file.
   *
   * @param options arguments to the pipeline
   */
  public static PipelineResult run(Pipeline pipeline, CdapZendeskOptions options) {
    Map<String, Object> pluginConfigParams =
        PluginConfigOptionsConverter.zendeskOptionsToParamsMap(options);
    LOG.info("Starting Cdap-Zendesk-To-Txt pipeline with parameters: {}", pluginConfigParams);

    /*
     * Steps:
     *  1) Read messages in from Cdap Zendesk
     *  2) Extract values only
     *  3) Write successful records to .txt file
     */

    pipeline
        .apply("readFromCdapZendesk", readFromCdapZendesk(pluginConfigParams))
        .setCoder(
            KvCoder.of(
                NullableCoder.of(WritableCoder.of(NullWritable.class)),
                SerializableCoder.of(StructuredRecord.class)))
        .apply(
            MapValues.into(TypeDescriptors.strings())
                .via(StructuredRecordUtils::structuredRecordToString))
        .setCoder(
            KvCoder.of(
                NullableCoder.of(WritableCoder.of(NullWritable.class)), StringUtf8Coder.of()))
        .apply(Values.create())
        .apply("writeToTxt", TextIO.write().to(options.getOutputTxtFilePathPrefix()));

    return pipeline.run();
  }
}
