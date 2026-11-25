# Ballerina OpenAI Responses connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-openai.responses/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.responses/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-openai.responses.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.responses/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/openai.responses.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fopenai.responses)

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

If the token changes between requests, for example a short-lived access token from OpenAI workload identity federation, leave out `auth` and pass the full `Authorization` header value in the `headers` of each request. When `auth` is set, the client replaces any `Authorization` header passed in `headers` with its own token. A client with neither sends requests without authentication, which OpenAI rejects with a `401` response.

```ballerina
final responses:Client openAIResponses = check new ({});

// In the function that makes the request:
responses:Response response = check openAIResponses->/responses.post(request,
    headers = {"Authorization": "Bearer " + accessToken});
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

    responses:Response response = check openAIResponses->/responses.post(request);
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

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export GitHub Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`openai.responses` package](https://central.ballerina.io/ballerinax/openai.responses/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
