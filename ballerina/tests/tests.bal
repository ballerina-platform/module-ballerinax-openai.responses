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

import ballerina/data.jsondata;
import ballerina/os;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("OPENAI_TOKEN") : "test";
final string mockServiceUrl = "http://localhost:9090";
final Client openAIResponses = check initClient();

function initClient() returns Client|error {
    if isLiveServer {
        return new ({auth: {token}});
    }
    return new ({auth: {token}}, mockServiceUrl);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponse() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "This is a test message"
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.id.length() > 0, msg = "Expected a non-empty response ID");
    test:assertEquals(response.'object, "response", msg = "Expected object type to be 'response'");
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");
    test:assertEquals(response.status, "completed", msg = "Expected status to be 'completed'");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithInstructions() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        instructions: "You are a helpful assistant. Keep responses brief.",
        input: "Say hello in one word."
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");
    OutputItem firstItem = response.output[0];
    test:assertTrue(firstItem is OutputMessage, msg = "Expected first output item to be an OutputMessage");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseOutputContent() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "This is a test message"
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");
    // Asserted unconditionally: guarding these behind `if firstItem is OutputMessage` made the
    // test pass vacuously whenever the response shape changed.
    OutputTextContent firstContent = check getFirstOutputTextContent(response);
    test:assertTrue(firstContent.text.length() > 0, msg = "Expected non-empty text in the response");
}

# Returns the first `OutputMessage` in the response. Reasoning and tool-call items may precede
# the assistant message, so the whole `output` array is scanned rather than just index 0.
isolated function getFirstOutputMessage(Response response) returns OutputMessage|error {
    foreach OutputItem item in response.output {
        if item is OutputMessage {
            return item;
        }
    }
    return error("Expected the response to contain an OutputMessage");
}

# Returns the first `OutputTextContent` in the response, or an error if there is none.
isolated function getFirstOutputTextContent(Response response) returns OutputTextContent|error {
    OutputMessage message = check getFirstOutputMessage(response);
    test:assertTrue(message.content.length() > 0, msg = "Expected content in the output message");
    OutputMessageContent firstContent = message.content[0];
    if firstContent !is OutputTextContent {
        return error("Expected the first content item to be an OutputTextContent");
    }
    return firstContent;
}

# Returns the raw JSON body of the last request the mock service received.
isolated function getLastRequestObject() returns map<json>|error {
    json body = getLastRequestBody();
    if body is () {
        return error("The mock service did not record a request body");
    }
    return body.ensureType();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithGpt5Reasoning() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "What is 2 + 2?",
        reasoning: {effort: "low"}
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    // Assert on what was actually serialised onto the wire, so that a regression in how
    // `model` or the nested `reasoning` record is encoded is caught here.
    map<json> body = check getLastRequestObject();
    test:assertEquals(body["model"], "gpt-5", msg = "Expected the gpt-5 model to be sent");
    map<json> reasoning = check body["reasoning"].ensureType();
    test:assertEquals(reasoning["effort"], "low", msg = "Expected reasoning effort 'low' to be sent");

    boolean hasReasoningItem = false;
    foreach OutputItem item in response.output {
        if item is ReasoningItem {
            hasReasoningItem = true;
        }
    }
    test:assertTrue(hasReasoningItem, msg = "Expected a ReasoningItem in the output");
    OutputTextContent content = check getFirstOutputTextContent(response);
    test:assertTrue(content.text.length() > 0, msg = "Expected non-empty assistant text");
    ResponseUsage? usage = response.usage;
    if usage is ResponseUsage {
        test:assertEquals(usage.output_tokens_details.reasoning_tokens, 7,
                msg = "Expected reasoning tokens to be reported for a reasoning request");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithMaxOutputTokens() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "Write a haiku about Ballerina.",
        max_output_tokens: 64
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    test:assertEquals(body["max_output_tokens"], 64, msg = "Expected max_output_tokens to be sent");
    test:assertEquals(response?.max_output_tokens, 64,
            msg = "Expected max_output_tokens to be echoed in the response");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithTextVerbosity() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "Explain recursion.",
        text: {verbosity: "low"}
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    map<json> text = check body["text"].ensureType();
    test:assertEquals(text["verbosity"], "low", msg = "Expected text.verbosity 'low' to be sent");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithTemperatureAndTopP() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "Say hello.",
        temperature: 0.2,
        top_p: 0.9
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    test:assertEquals(body["temperature"], 0.2d, msg = "Expected temperature to be sent");
    test:assertEquals(body["top_p"], 0.9d, msg = "Expected top_p to be sent");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithFunctionTool() returns error? {
    FunctionTool weatherTool = {
        'type: "function",
        name: "get_weather",
        description: "Get the current weather for a city",
        parameters: {
            "type": "object",
            "properties": {"location": {"type": "string"}},
            "required": ["location"],
            "additionalProperties": false
        },
        strict: true
    };
    CreateResponse request = {
        model: "gpt-5",
        input: "What is the weather in Colombo?",
        tools: [weatherTool],
        tool_choice: "auto"
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    json[] tools = check body["tools"].ensureType();
    test:assertEquals(tools.length(), 1, msg = "Expected exactly one tool to be sent");
    map<json> tool = check tools[0].ensureType();
    test:assertEquals(tool["type"], "function", msg = "Expected a function tool to be sent");
    test:assertEquals(tool["name"], "get_weather", msg = "Expected the tool name to be sent");
    test:assertEquals(tool["strict"], true, msg = "Expected strict mode to be sent");
    test:assertEquals(body["tool_choice"], "auto", msg = "Expected tool_choice to be sent");

    OutputItem firstItem = response.output[0];
    test:assertTrue(firstItem is FunctionToolCall, msg = "Expected a FunctionToolCall in the output");
    if firstItem is FunctionToolCall {
        test:assertEquals(firstItem.name, "get_weather", msg = "Expected the model to call get_weather");
        test:assertTrue(firstItem.arguments.length() > 0, msg = "Expected non-empty call arguments");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithStructuredOutput() returns error? {
    TextResponseFormatJsonSchema jsonSchema = {
        'type: "json_schema",
        name: "weather_report",
        schema: {
            "type": "object",
            "properties": {
                "city": {"type": "string"},
                "temperature": {"type": "number"}
            },
            "required": ["city", "temperature"],
            "additionalProperties": false
        },
        strict: true
    };
    CreateResponse request = {
        model: "gpt-5",
        input: "Report the weather in Colombo.",
        text: {format: jsonSchema}
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    map<json> text = check body["text"].ensureType();
    map<json> format = check text["format"].ensureType();
    test:assertEquals(format["type"], "json_schema", msg = "Expected a json_schema format to be sent");
    test:assertEquals(format["name"], "weather_report", msg = "Expected the schema name to be sent");
    test:assertEquals(format["strict"], true, msg = "Expected strict mode to be sent");

    OutputTextContent content = check getFirstOutputTextContent(response);
    map<json> parsed = check content.text.fromJsonStringWithType();
    test:assertEquals(parsed["city"], "Colombo", msg = "Expected the structured output to parse as JSON");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithWebSearchTool() returns error? {
    WebSearchTool searchTool = {'type: "web_search"};
    CreateResponse request = {
        model: "gpt-5",
        input: "What is the Ballerina language?",
        tools: [searchTool]
    };
    Response response = check openAIResponses->/responses.post(request);

    map<json> body = check getLastRequestObject();
    json[] tools = check body["tools"].ensureType();
    map<json> tool = check tools[0].ensureType();
    test:assertEquals(tool["type"], "web_search", msg = "Expected a web_search tool to be sent");

    boolean hasSearchCall = false;
    foreach OutputItem item in response.output {
        if item is WebSearchToolCall {
            hasSearchCall = true;
            test:assertEquals(item.status, "completed", msg = "Expected the search call to be completed");
        }
    }
    test:assertTrue(hasSearchCall, msg = "Expected a WebSearchToolCall in the output");
    OutputTextContent content = check getFirstOutputTextContent(response);
    test:assertTrue(content.text.length() > 0, msg = "Expected assistant text alongside the search call");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithBackground() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "Summarise the history of Sri Lanka.",
        background: true
    };
    Response response = check openAIResponses->/responses.post(request);

    map<json> body = check getLastRequestObject();
    test:assertEquals(body["background"], true, msg = "Expected background to be sent");
    test:assertEquals(response.status, "queued", msg = "Expected a backgrounded response to be queued");
    test:assertEquals(response.output.length(), 0, msg = "Expected no output for a queued response");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseIncompleteWhenTruncated() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "Write a long essay.",
        max_output_tokens: 16
    };
    Response response = check openAIResponses->/responses.post(request);

    test:assertEquals(response.status, "incomplete", msg = "Expected an incomplete response");
    ResponseIncompleteDetails? details = response.incomplete_details;
    test:assertTrue(details is ResponseIncompleteDetails, msg = "Expected incomplete_details to be populated");
    if details is ResponseIncompleteDetails {
        test:assertEquals(details.reason, "max_output_tokens",
                msg = "Expected the truncation reason to be max_output_tokens");
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithMultimodalInput() returns error? {
    // A 1x1 transparent PNG, so the request carries a real data URL without needing a fixture.
    string base64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk" +
        "YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";
    InputContent[] messageContent = [
        {'type: "input_text", text: "Describe this image."},
        {'type: "input_image", image_url: string `data:image/png;base64,${base64Image}`, detail: "auto"}
    ];
    EasyInputMessage userMessage = {role: "user", content: messageContent};
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: [userMessage]
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    map<json> body = check getLastRequestObject();
    json[] input = check body["input"].ensureType();
    map<json> message = check input[0].ensureType();
    test:assertEquals(message["role"], "user", msg = "Expected the message role to be sent");
    json[] content = check message["content"].ensureType();
    test:assertEquals(content.length(), 2, msg = "Expected both content parts to be sent");
    map<json> textPart = check content[0].ensureType();
    map<json> imagePart = check content[1].ensureType();
    test:assertEquals(textPart["type"], "input_text", msg = "Expected an input_text part");
    test:assertEquals(imagePart["type"], "input_image", msg = "Expected an input_image part");
    test:assertEquals(imagePart["detail"], "auto", msg = "Expected the image detail to be sent");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateResponseWithMetadataAndStore() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "Say hello.",
        metadata: {"conversation": "test-suite", "stage": "regression"},
        store: false
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0, msg = "Expected at least one output item");

    if isLiveServer {
        return;
    }
    map<json> body = check getLastRequestObject();
    map<json> metadata = check body["metadata"].ensureType();
    test:assertEquals(metadata["conversation"], "test-suite", msg = "Expected metadata to be sent");
    test:assertEquals(body["store"], false, msg = "Expected store to be sent");
    Metadata? echoed = response.metadata;
    test:assertTrue(echoed is Metadata, msg = "Expected metadata to be echoed in the response");
    if echoed is Metadata {
        test:assertEquals(echoed["stage"], "regression", msg = "Expected the metadata value to round-trip");
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithPreviousResponseId() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "And what about tomorrow?",
        previous_response_id: "resp-mock00000"
    };
    Response response = check openAIResponses->/responses.post(request);

    map<json> body = check getLastRequestObject();
    test:assertEquals(body["previous_response_id"], "resp-mock00000",
            msg = "Expected previous_response_id to be sent");
    test:assertEquals(response?.previous_response_id, "resp-mock00000",
            msg = "Expected previous_response_id to be echoed in the response");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithRefusalContent() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "Please refuse this request."
    };
    Response response = check openAIResponses->/responses.post(request);

    OutputMessage message = check getFirstOutputMessage(response);
    test:assertTrue(message.content.length() > 0, msg = "Expected content in the output message");
    OutputMessageContent firstContent = message.content[0];
    test:assertTrue(firstContent is RefusalContent, msg = "Expected a RefusalContent item");
    if firstContent is RefusalContent {
        test:assertTrue(firstContent.refusal.length() > 0, msg = "Expected a non-empty refusal message");
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testOutputTextContentWithoutLogprobs() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "This is a test message"
    };
    Response response = check openAIResponses->/responses.post(request);
    OutputTextContent content = check getFirstOutputTextContent(response);
    test:assertTrue(content.logprobs is (),
            msg = "Expected logprobs to be absent when it was not requested via 'include'");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testOutputTextContentWithLogprobs() returns error? {
    CreateResponse request = {
        model: "gpt-4o-mini",
        input: "This is a test message",
        include: ["message.output_text.logprobs"]
    };
    Response response = check openAIResponses->/responses.post(request);

    map<json> body = check getLastRequestObject();
    json[] include = check body["include"].ensureType();
    test:assertEquals(include[0], "message.output_text.logprobs", msg = "Expected include to be sent");

    OutputTextContent content = check getFirstOutputTextContent(response);
    LogProb[]? logprobs = content.logprobs;
    test:assertTrue(logprobs is LogProb[],
            msg = "Expected logprobs to be present when requested via 'include'");
    if logprobs is LogProb[] {
        test:assertTrue(logprobs.length() > 0, msg = "Expected at least one logprob entry");
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testCreateResponseWithInvalidModelReturnsError() {
    CreateResponse request = {
        model: "",
        input: "This is a test message"
    };
    Response|error response = openAIResponses->/responses.post(request);
    test:assertTrue(response is error, msg = "Expected an error for a request with no model");
}

// Guards the sanitation that removed `default:` from the request-body sampling
// parameters. A parameter the caller never set must not appear in the serialised
// body: the reasoning models (o-series, gpt-5 family) reject the *presence* of
// these keys, so a defaulted-but-always-present field made those models
// uncallable. `jsondata:toJson` is the exact serialiser used by `client.bal`.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testUnsetRequestParametersAreNotSerialized() returns error? {
    CreateResponse request = {
        model: "gpt-5",
        input: "This is a test message"
    };

    map<json> body = check jsondata:toJson(request).ensureType();
    foreach string paramName in ["temperature", "top_p", "parallel_tool_calls", "store", "stream", "background", "truncation"] {
        test:assertFalse(body.hasKey(paramName),
                msg = string `Expected '${paramName}' to be omitted when the caller does not set it`);
    }

    // An explicitly set parameter must still be serialised.
    request.temperature = 0.2;
    map<json> bodyWithTemperature = check jsondata:toJson(request).ensureType();
    test:assertEquals(bodyWithTemperature["temperature"], 0.2d,
            msg = "Expected an explicitly set temperature to be sent");
}
