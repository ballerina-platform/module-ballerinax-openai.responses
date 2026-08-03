## Image to markdown document converter

This use case demonstrates how the OpenAI Responses API can be utilized to generate markdown documentation from visual content. It starts by converting an image file—such as a whiteboard sketch or diagram—into a base64-encoded string. Using the OpenAI Responses API's vision capabilities it generates a markdown document that includes detailed descriptions of the image's contents, such as diagrams, notes, or code snippets. The resulting markdown is structured with appropriate headings and summaries, and saved as a `.md` file in the same directory as the original image.

## Prerequisites

1. Generate an API key as described in the [Setup guide](https://central.ballerina.io/ballerinax/openai.responses/latest#setup-guide).

2. For each example, create a `Config.toml` file with the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    token = "<API Key>"
    ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```
