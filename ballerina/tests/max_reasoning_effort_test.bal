// Copyright (c) 2026 WSO2 LLC (http://www.wso2.com).
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;

@test:Config {
    groups: ["mock_tests", "max_reasoning"]
}
isolated function testCreateResponseWithMaxReasoningEffort() returns error? {
    CreateResponse request = {
        model: "gpt-6-astra",
        input: "What is 2 + 2?",
        reasoning: {effort: "max"}
    };
    Response response = check openAIResponses->/responses.post(request);
    test:assertTrue(response.output.length() > 0);

    map<json> body = check getLastRequestObject();
    test:assertEquals(body["model"], "gpt-6-astra");
    map<json> reasoning = check body["reasoning"].ensureType();
    test:assertEquals(reasoning["effort"], "max", "Maximum reasoning effort must reach the nested HTTP field");
}
