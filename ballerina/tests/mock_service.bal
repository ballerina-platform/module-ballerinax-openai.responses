// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

listener http:Listener httpListener = new (9090);

# Holds the raw JSON body of the most recent request received by the mock service, so that tests
# can assert on what was actually serialised onto the wire rather than only on the response.
isolated json? lastRequestBody = ();

isolated function setLastRequestBody(json body) {
    lock {
        lastRequestBody = body.clone();
    }
}

# Returns the raw JSON body of the most recent request received by the mock service.
isolated function getLastRequestBody() returns json {
    lock {
        json? body = lastRequestBody;
        return body is () ? () : body.clone();
    }
}

# Builds a mock `Response` that echoes back the request-scoped fields, so that tests can assert
# that a parameter both serialised correctly and round-tripped.
isolated function buildMockResponse(CreateResponse request, OutputItem[] output,
        "completed"|"failed"|"in_progress"|"cancelled"|"queued"|"incomplete" status = "completed",
        ResponseIncompleteDetails? incompleteDetails = (), int reasoningTokens = 0) returns Response =>
    {
        id: "resp-mock00000",
        'object: "response",
        created_at: 1723091495,
        model: request?.model ?: "gpt-4o-mini-2024-07-18",
        status: status,
        instructions: request?.instructions,
        metadata: request?.metadata,
        tool_choice: request?.tool_choice ?: "auto",
        tools: request?.tools ?: [],
        max_output_tokens: request?.max_output_tokens,
        background: request?.background,
        previous_response_id: request?.previous_response_id,
        output: output,
        'error: (),
        incomplete_details: incompleteDetails,
        usage: {
            input_tokens: 13,
            output_tokens: 11,
            total_tokens: 24,
            input_tokens_details: {cached_tokens: 0},
            output_tokens_details: {reasoning_tokens: reasoningTokens}
        }
    };

# Wraps content items in a completed assistant message.
isolated function assistantMessage(OutputMessageContent[] content) returns OutputMessage =>
    {
        id: "msg-mock00000",
        'type: "message",
        role: "assistant",
        status: "completed",
        content: content
    };

# Builds an `output_text` content item. `logprobs` is only attached when the caller opted in,
# which mirrors the real API and keeps the default path free of the key.
isolated function outputText(string text, boolean withLogprobs) returns OutputTextContent {
    if withLogprobs {
        return {
            'type: "output_text",
            text: text,
            annotations: [],
            logprobs: [{token: "Test", logprob: -0.1, bytes: [84, 101, 115, 116], top_logprobs: []}]
        };
    }
    return {'type: "output_text", text: text, annotations: []};
}

# Returns true when `include` opts in to `message.output_text.logprobs`.
isolated function wantsLogprobs(CreateResponse request) returns boolean {
    IncludeEnum[]? include = request?.include;
    if include is IncludeEnum[] {
        IncludeEnum logprobsInclude = "message.output_text.logprobs";
        return include.indexOf(logprobsInclude) != ();
    }
    return false;
}

# Returns the first function tool declared in the request, if any.
isolated function firstFunctionTool(CreateResponse request) returns FunctionTool? {
    ToolsArray? tools = request?.tools;
    if tools is ToolsArray {
        foreach Tool tool in tools {
            if tool is FunctionTool {
                return tool;
            }
        }
    }
    return ();
}

# Returns true when the request declares a built-in web search tool.
isolated function hasWebSearchTool(CreateResponse request) returns boolean {
    ToolsArray? tools = request?.tools;
    if tools is ToolsArray {
        foreach Tool tool in tools {
            if tool is WebSearchTool || tool is WebSearchPreviewTool {
                return true;
            }
        }
    }
    return false;
}

# Returns the JSON schema text format configuration, if the request asked for one.
isolated function jsonSchemaFormat(CreateResponse request) returns TextResponseFormatJsonSchema? {
    ResponseTextParam? text = request?.text;
    if text is ResponseTextParam {
        TextResponseFormatConfiguration? format = text?.format;
        if format is TextResponseFormatJsonSchema {
            return format;
        }
    }
    return ();
}

http:Service mockService = service object {
    // The payload is bound as `json` rather than as `CreateResponse` so that tests can assert on
    // the exact wire representation, including whether optional fields were emitted at all.
    resource function post responses(@http:Payload json payload)
        returns Response|http:BadRequest {
        setLastRequestBody(payload);

        CreateResponse|error binding = payload.cloneWithType();
        if binding is error {
            return http:BAD_REQUEST;
        }
        CreateResponse request = binding;

        // Validate the request payload
        if request?.model.toString() == "" {
            return http:BAD_REQUEST;
        }

        boolean withLogprobs = wantsLogprobs(request);

        // A backgrounded response is accepted immediately and produces no output yet.
        if request?.background == true {
            return buildMockResponse(request, [], "queued");
        }

        // A function tool call short-circuits the assistant message.
        FunctionTool? functionTool = firstFunctionTool(request);
        if functionTool is FunctionTool {
            FunctionToolCall call = {
                id: "fc-mock00000",
                'type: "function_call",
                call_id: "call-mock00000",
                name: functionTool.name,
                arguments: "{\"location\":\"Colombo\"}",
                status: "completed"
            };
            return buildMockResponse(request, [call]);
        }

        // A built-in web search tool emits the search call alongside the message.
        if hasWebSearchTool(request) {
            WebSearchToolCall searchCall = {
                id: "ws-mock00000",
                'type: "web_search_call",
                status: "completed",
                action: {'type: "search", query: "ballerina language"}
            };
            return buildMockResponse(request,
                    [searchCall, assistantMessage([outputText("Ballerina is a language.", withLogprobs)])]);
        }

        // Structured outputs echo a JSON document rather than prose.
        TextResponseFormatJsonSchema? jsonSchema = jsonSchemaFormat(request);
        if jsonSchema is TextResponseFormatJsonSchema {
            return buildMockResponse(request,
                    [assistantMessage([outputText("{\"city\":\"Colombo\",\"temperature\":30}", withLogprobs)])]);
        }

        // A reasoning request emits a reasoning item and reports reasoning tokens.
        // NOTE: `ReasoningEffort` is itself a nilable union, so `effort is ReasoningEffort` is
        // true even when the field is absent. Compare against nil explicitly instead.
        ReasoningEffort? effort = request?.reasoning?.effort;
        if effort != () && effort != "none" {
            ReasoningItem reasoningItem = {
                'type: "reasoning",
                id: "rs-mock00000",
                summary: [{'type: "summary_text", text: "Considered the question."}],
                status: "completed"
            };
            return buildMockResponse(request,
                    [reasoningItem, assistantMessage([outputText("The answer is 4.", withLogprobs)])],
                    reasoningTokens = 7);
        }

        // A very small token budget truncates the response.
        int? maxOutputTokens = request?.max_output_tokens;
        if maxOutputTokens is int && maxOutputTokens <= 16 {
            return buildMockResponse(request,
                    [assistantMessage([outputText("Truncated", withLogprobs)])],
                    "incomplete", {reason: "max_output_tokens"});
        }

        // A refusal is returned instead of text when the input asks for something disallowed.
        InputParam? input = request?.input;
        if input is string && input.toLowerAscii().includes("refuse") {
            RefusalContent refusal = {'type: "refusal", refusal: "I cannot help with that."};
            return buildMockResponse(request, [assistantMessage([refusal])]);
        }

        return buildMockResponse(request,
                [assistantMessage([outputText("Test response received! How can I assist you today?", withLogprobs)])]);
    }
};

function init() returns error? {
    if isLiveServer {
        log:printInfo("Skipping mock server initialization as the tests are running on live server");
        return;
    }

    log:printInfo("Initiating mock server...");
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}
