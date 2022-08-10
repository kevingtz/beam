/*
 *  Copyright © 2019 Cask Data, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not
 *  use this file except in compliance with the License. You may obtain a copy of
 *  the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations under
 *  the License.
 */
package io.cdap.plugin.zuora.objects;

import com.google.gson.annotations.SerializedName;
import io.cdap.cdap.api.data.schema.Schema;
import io.cdap.plugin.zuora.restobjects.annotations.ObjectDefinition;
import io.cdap.plugin.zuora.restobjects.annotations.ObjectFieldDefinition;
import io.cdap.plugin.zuora.restobjects.objects.BaseObject;


import javax.annotation.Nullable;

/**
* Object name: ProxyGetRefundInvoicePayment (ProxyGetRefundInvoicePayment).
* Related objects:
**/
@SuppressWarnings("unused")
@ObjectDefinition(
  Name = "ProxyGetRefundInvoicePayment",
  ObjectType = ObjectDefinition.ObjectDefinitionType.NESTED
)
public class ProxyGetRefundInvoicePayment extends BaseObject {
  /**
  * Name: CreatedById (CreatedById), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("createdById")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String createdById;

  /**
  * Name: CreatedDate (CreatedDate), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("createdDate")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String createdDate;

  /**
  * Name: Id (Id), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("id")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String id;

  /**
  * Name: InvoiceId (InvoiceId), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("invoiceId")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String invoiceId;

  /**
  * Name: InvoicePaymentId (InvoicePaymentId), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("invoicePaymentId")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String invoicePaymentId;

  /**
  * Name: RefundAmount (RefundAmount), Type: number.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("refundAmount")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String refundAmount;

  /**
  * Name: RefundId (RefundId), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("refundId")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String refundId;

  /**
  * Name: UpdatedById (UpdatedById), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("updatedById")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String updatedById;

  /**
  * Name: UpdatedDate (UpdatedDate), Type: string.
  * Options (custom, update, select): false, false, false
  **/
  @Nullable
  @SerializedName("updatedDate")
  @ObjectFieldDefinition(FieldType = Schema.Type.STRING)
  private String updatedDate;


  @Override
  public void addFields() {
    addCustomField("createdById", createdById, String.class);
    addCustomField("createdDate", createdDate, String.class);
    addCustomField("id", id, String.class);
    addCustomField("invoiceId", invoiceId, String.class);
    addCustomField("invoicePaymentId", invoicePaymentId, String.class);
    addCustomField("refundAmount", refundAmount, String.class);
    addCustomField("refundId", refundId, String.class);
    addCustomField("updatedById", updatedById, String.class);
    addCustomField("updatedDate", updatedDate, String.class);
  }
}
