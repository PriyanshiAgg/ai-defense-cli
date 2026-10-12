// Copyright 2026 Cisco Systems, Inc. and its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

package clierror

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/cisco-ai-defense/ai-defense-cli/api"
)

func TestClassifyAPIError(t *testing.T) {
	tests := []struct {
		name     string
		status   int
		wantCode int
		wantHint bool
	}{
		{"bad request", 400, CodeUsage, true},
		{"unauthorized", 401, CodeAuth, true},
		{"forbidden", 403, CodeAuth, true},
		{"not found", 404, CodeScanFailed, true},
		{"rate limited", 429, CodeNetwork, true},
		{"server error", 500, CodeNetwork, true},
		{"bad gateway", 503, CodeNetwork, true},
		{"teapot/unknown", 418, CodeUnexpected, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := &api.ApiError{StatusCode: tt.status, Message: "boom", RequestID: "req-1"}
			got := Classify(err)
			if got.Code != tt.wantCode {
				t.Fatalf("status %d: want code %d, got %d", tt.status, tt.wantCode, got.Code)
			}
			if got.RequestID != "req-1" {
				t.Errorf("status %d: request id not propagated, got %q", tt.status, got.RequestID)
			}
			if (got.Hint != "") != tt.wantHint {
				t.Errorf("status %d: want hint=%v, got hint=%q", tt.status, tt.wantHint, got.Hint)
			}
		})
	}
}

func TestClassifyTransportError(t *testing.T) {
	err := &api.TransportError{
		Method: "GET",
		URL:    "https://tenant.aidefense.aiteam.cisco.com/api/ai-defense/v1/scans",
		Cause:  context.DeadlineExceeded,
	}
	got := Classify(err)
	if got.Code != CodeNetwork {
		t.Fatalf("want CodeNetwork, got %d", got.Code)
	}
	if got.Hint == "" {
		t.Fatal("expected network hint")
	}
	if !strings.Contains(got.Message, "timed out") {
		t.Fatalf("expected timeout message, got %q", got.Message)
	}
}

func TestClassifyPollTimeoutError(t *testing.T) {
	t.Run("model scan", func(t *testing.T) {
		got := Classify(&api.PollTimeoutError{
			ScanID:        "scan-1",
			BudgetSecs:    600,
			StatusCommand: "cisco-aid-cli model-scan info --scan-id scan-1",
			BudgetEnvVars: []string{"AI_DEFENSE_RETRY_COUNT_FOR_SCANNING", "AI_DEFENSE_WAIT_TIME_SECS_SUCCESSIVE_SCAN_INFO_CHECK"},
		})
		if got.Code != CodeNetwork {
			t.Fatalf("want CodeNetwork, got %d", got.Code)
		}
		for _, s := range []string{
			"still running on the server and was not cancelled",
			"cisco-aid-cli model-scan info --scan-id scan-1",
			"AI_DEFENSE_RETRY_COUNT_FOR_SCANNING and/or AI_DEFENSE_WAIT_TIME_SECS_SUCCESSIVE_SCAN_INFO_CHECK",
		} {
			if !strings.Contains(got.Hint, s) {
				t.Errorf("hint %q missing %q", got.Hint, s)
			}
		}
		if strings.Contains(strings.ToLower(got.Hint), "re-run") {
			t.Errorf("hint must not suggest re-running: %q", got.Hint)
		}
	})

	t.Run("without status command keeps the existing hint", func(t *testing.T) {
		got := Classify(&api.PollTimeoutError{ScanID: "scan-2", BudgetSecs: 300})
		if got.Code != CodeNetwork {
			t.Fatalf("want CodeNetwork, got %d", got.Code)
		}
		if !strings.Contains(got.Hint, "Increase the polling budget") {
			t.Errorf("hint = %q, want the existing polling-budget hint", got.Hint)
		}
	})
}

func TestClassifyValidationError(t *testing.T) {
	err := &api.ValidationError{Message: "bad input"}
	got := Classify(err)
	if got.Code != CodeUsage {
		t.Fatalf("want CodeUsage, got %d", got.Code)
	}
	if got.Message != "bad input" {
		t.Errorf("want message preserved, got %q", got.Message)
	}
}

func TestClassifyPassThroughTypedError(t *testing.T) {
	in := Gate(CodeBlock, "blocked")
	got := Classify(in)
	if got != in {
		t.Fatalf("expected the same *Error to be returned unchanged")
	}
	if got.Code != CodeBlock {
		t.Errorf("want CodeBlock, got %d", got.Code)
	}
}

func TestClassifyWrappedTypedError(t *testing.T) {
	in := Auth("no creds", "set --api-key", nil)
	wrapped := fmt.Errorf("context: %w", in)
	got := Classify(wrapped)
	if got.Code != CodeAuth {
		t.Fatalf("want CodeAuth through wrapping, got %d", got.Code)
	}
}

func TestClassifyUnknownError(t *testing.T) {
	got := Classify(errors.New("something odd"))
	if got.Code != CodeUnexpected {
		t.Fatalf("want CodeUnexpected, got %d", got.Code)
	}
}

func TestClassifyNil(t *testing.T) {
	if got := Classify(nil); got != nil {
		t.Fatalf("want nil for nil error, got %#v", got)
	}
}

func TestErrorUnwrap(t *testing.T) {
	cause := errors.New("root")
	e := Network("net down", "check vpn", cause)
	if !errors.Is(e, cause) {
		t.Fatalf("expected errors.Is to find the cause")
	}
}
