## Overview

[OpenAI](https://openai.com/), an AI research organization focused on creating friendly AI for humanity, offers the [OpenAI API](https://platform.openai.com/docs/api-reference/introduction) to access its powerful AI models for tasks like natural language processing and image generation.

The `ballerinax/openai.responses` package offers functionality to connect and interact with the [Responses API of the OpenAI REST API](https://platform.openai.com/docs/api-reference/responses). The Responses API is OpenAI's most advanced interface for generating model responses — an evolution of Chat Completions that brings added simplicity and powerful agentic primitives such as built-in tools for web search and file search.

The package currently exposes the [create model response](https://platform.openai.com/docs/api-reference/responses/create) operation (`POST /responses`), which covers text and image inputs, text and JSON outputs, function calling, and the built-in tools.

## Setup guide

To use the OpenAI Connector, you must have access to the OpenAI API through an [OpenAI Platform account](https://platform.openai.com) and a project under it. If you do not have a OpenAI Platform account, you can sign up for one [here](https://platform.openai.com/signup).

#### Create an OpenAI API Key

1. Open the [OpenAI Platform Dashboard](https://platform.openai.com).

2. Navigate to Dashboard -> API keys.
<img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-openai.responses/main/docs/setup/resources/navigate-api-key-dashboard.png alt="OpenAI Platform" style="width: 70%;">

3. Click on the "Create new secret key" button.
<img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-openai.responses/main/docs/setup/resources/api-key-dashboard.png alt="OpenAI Platform" style="width: 70%;">

4. Fill the details and click on Create secret key.
<img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-openai.responses/main/docs/setup/resources/create-new-secret-key.png alt="OpenAI Platform" style="width: 70%;">

5. Store the API key securely to use in your application.
<img src=https://raw.githubusercontent.com/ballerina-platform/module-ballerinax-openai.responses/main/docs/setup/resources/saved-key.png alt="OpenAI Platform" style="width: 70%;">

## Quickstart

To use the `OpenAI Responses` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/openai.responses` module.

```ballerina
import ballerinax/openai.responses;
```

### Step 2: Create a new connector instance

Create a `responses:Client` with the obtained API Key and initialize the connector.

```ballerina
configurable string token = ?;

final responses:Client openAIResponses = check new ({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, you can utilize the available connector operation.

#### Create a model response

```ballerina
public function main() returns error? {
    responses:CreateResponse request = {
        model: "gpt-4o-mini",
        input: "What is Ballerina programming language?"
    };

    responses:Response response =
        check openAIResponses->/responses.post(request);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `OpenAI Responses` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples/), covering the following use cases:

1. [CLI assistant](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples/cli-assistant) - Execute the user's task description by generating and running the appropriate command in the command line interface of their selected operating system.
2. [Image to markdown document converter](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples/image-to-markdown-converter) - Generate detailed markdown documentation based on the image content.
