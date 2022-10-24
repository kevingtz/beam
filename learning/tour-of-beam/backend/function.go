// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package tob

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"

	tob "beam.apache.org/learning/tour-of-beam/backend/internal"
	"beam.apache.org/learning/tour-of-beam/backend/internal/service"
	"beam.apache.org/learning/tour-of-beam/backend/internal/storage"
	"cloud.google.com/go/datastore"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

var (
	svc  service.IContent
	auth *Authorizer
)

// Helper to format http error messages.
func finalizeErrResponse(w http.ResponseWriter, status int, code, message string) {
	resp := tob.CodeMessage{Code: code, Message: message}

	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(resp)
}

func MakeService(ctx context.Context) service.IContent {
	// dependencies
	// required:
	// * TOB_MOCK: respond with static samples
	// OR
	// * GOOGLE_APPLICATION_CREDENTIALS: json file path to cloud credentials
	// * DATASTORE_PROJECT_ID: cloud project id
	// optional:
	// * DATASTORE_EMULATOR_HOST: emulator host/port (ex. 0.0.0.0:8888)
	if os.Getenv("TOB_MOCK") > "" {
		fmt.Println("Initialize mock service")
		return &service.Mock{}
	} else {
		// consumes DATASTORE_* env variables
		client, err := datastore.NewClient(ctx, "")
		if err != nil {
			log.Fatalf("new datastore client: %v", err)
		}

		return &service.Svc{Repo: &storage.DatastoreDb{Client: client}}
	}
}

func init() {
	ctx := context.Background()

	svc = MakeService(ctx)
	auth = MakeAuthorizer(ctx)

	// functions framework
	functions.HTTP("getSdkList", Common(getSdkList))
	functions.HTTP("getContentTree", Common(ParseSdkParam(getContentTree)))
	functions.HTTP("getUnitContent", Common(ParseSdkParam(getUnitContent)))

	functions.HTTP("getUserProgress", Common(ParseSdkParam(auth.ParseAuthHeader(getUserProgress))))
}

// Get list of SDK names
// Used in both representation and accessing content.
func getSdkList(w http.ResponseWriter, r *http.Request) {
	sdks := tob.MakeSdkList()

	err := json.NewEncoder(w).Encode(sdks)
	if err != nil {
		log.Println("Format sdk list error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "format sdk list")
		return
	}
}

// Get the content tree for a given SDK
// Required to be wrapped into ParseSdkParam middleware.
func getContentTree(w http.ResponseWriter, r *http.Request, sdk tob.Sdk) {
	tree, err := svc.GetContentTree(r.Context(), sdk)
	if err != nil {
		log.Println("Get content tree error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "storage error")
		return
	}

	err = json.NewEncoder(w).Encode(tree)
	if err != nil {
		log.Println("Format content tree error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "format content tree")
		return
	}
}

// Get unit content
// Everything needed to render a learning unit:
// description, hints, code snippets
// Required to be wrapped into ParseSdkParam middleware.
func getUnitContent(w http.ResponseWriter, r *http.Request, sdk tob.Sdk) {
	unitId := r.URL.Query().Get("id")

	unit, err := svc.GetUnitContent(r.Context(), sdk, unitId)
	if errors.Is(err, tob.ErrNoUnit) {
		finalizeErrResponse(w, http.StatusNotFound, NOT_FOUND, "unit not found")
		return
	}
	if err != nil {
		log.Println("Get unit content error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "storage error")
		return
	}

	err = json.NewEncoder(w).Encode(unit)
	if err != nil {
		log.Println("Format unit content error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "format unit content")
		return
	}
}

// Get user progress
func getUserProgress(w http.ResponseWriter, r *http.Request, sdk tob.Sdk, uid string) {
	progress, err := svc.GetUserProgress(r.Context(), sdk, uid)

	if err != nil {
		log.Println("Get user progress error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "storage error")
		return
	}

	err = json.NewEncoder(w).Encode(progress)
	if err != nil {
		log.Println("Format user progress error:", err)
		finalizeErrResponse(w, http.StatusInternalServerError, INTERNAL_ERROR, "format user progress content")
		return
	}
}
