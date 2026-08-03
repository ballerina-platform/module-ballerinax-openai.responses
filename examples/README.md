# Examples

The `ballerinax/openai.responses` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples), covering use cases like text generation and image understanding.

1. [CLI assistant](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples/cli-assistant) - Execute the user's task description by generating and running the appropriate command in the command line interface of their selected operating system.
2. [Image to markdown document converter](https://github.com/ballerina-platform/module-ballerinax-openai.responses/tree/main/examples/image-to-markdown-converter) - Generate detailed markdown documentation based on the image content.

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

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
