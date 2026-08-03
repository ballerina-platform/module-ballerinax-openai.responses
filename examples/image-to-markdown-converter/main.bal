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

import ballerina/file;
import ballerina/io;
import ballerinax/openai.responses;

configurable string token = ?;

public function main() returns error? {
    final responses:Client openAIResponses = check new ({auth: {token}});
    string imagePath = getImageFilePath();
    string|error base64Image = encodeImageToBase64(imagePath);

    if base64Image is error {
        io:println(base64Image);
        return;
    }
    string|error markdownDoc = generateDocumentation(base64Image, openAIResponses);

    if markdownDoc is error {
        io:println(markdownDoc);
        return;
    }
    check saveMarkdownToFile(markdownDoc, imagePath);
    io:println("Markdown documentation generated and saved successfully.");
}

function getImageFilePath() returns string {
    io:println("Enter the path to the image file:");
    return io:readln().trim();
}

function encodeImageToBase64(string imagePath) returns string|error {
    byte[] imageBytes = check io:fileReadBytes(imagePath);
    return imageBytes.toBase64();
}

function generateDocumentation(string base64Image, responses:Client openAIResponses) returns string|error {
    string prompt = "Generate markdown documentation based on the content of the following image. Include detailed descriptions of any diagrams, notes, or code snippets present. Structure the documentation with appropriate headings, and provide a summary of the key concepts discussed. Additionally, include any relevant annotations or comments that might aid in understanding the content";

    responses:CreateResponse request = {
        model: "gpt-4o-mini",
        input: [
            {
                role: "user",
                content: [
                    {
                        "type": "input_text",
                        "text": prompt
                    },
                    {
                        "type": "input_image",
                        "image_url": string `data:image/jpeg;base64,${base64Image}`,
                        "detail": "auto"
                    }
                ]
            }
        ],
        max_output_tokens: 300
    };

    responses:Response response = check openAIResponses->/responses.post(request);

    responses:OutputItem[] output = response.output;
    if output.length() == 0 {
        return error("No output received from the model.");
    }

    responses:OutputItem firstItem = output[0];
    if firstItem is responses:OutputMessage {
        responses:OutputMessageContent[] content = firstItem.content;
        if content.length() > 0 && content[0] is responses:OutputTextContent {
            return (<responses:OutputTextContent>content[0]).text;
        }
    }
    return error("Failed to generate markdown documentation.");
}

function saveMarkdownToFile(string markdownDoc, string imagePath) returns error? {
    string imageName = check file:basename(imagePath);
    string parentPath = check file:parentPath(imagePath);
    string docName = string `${re `\.`.split(imageName)[0]}_documentation.md`;
    check io:fileWriteBytes(parentPath + "/" + docName, markdownDoc.toBytes());
}
