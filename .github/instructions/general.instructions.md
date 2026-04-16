---
applyTo: "**"
---

# GitHub Copilot Instructions

This repo is meant to be educational and is not meant to be used in production. The code is not optimized for performance or security. The code is meant to be a starting point for learning and experimentation. The code is not meant to be used as a reference for best practices or design patterns. The code is meant to be a sandbox for learning and experimentation. The code is not meant to be used as a template for production code. The code is meant to be a playground for learning and experimentation. The code is not meant to be used as a boilerplate for production code. The code is meant to be a learning resource and is not meant to be used in production.

Please create educational resources as simple as possible with the less dependencies as possible. The code should be easy to understand and easy to run. The code should be well commented and well documented. The code should be easy to read and easy to follow. The code should be easy to modify and easy to extend. The code should be easy to debug and easy to troubleshoot. The code should be easy to test and easy to validate. The code should be easy to deploy and easy to scale. The code should be easy to maintain and easy to update. The code should be easy to learn and easy to teach. The code should be easy to share and easy to collaborate on. The code should be easy to use and easy to integrate with other tools and technologies.

Explain everything like its for someone new to programming and system design. Assume the reader has no prior knowledge of the concepts being discussed. Use simple language and avoid technical jargon as much as possible. Provide clear explanations and examples to illustrate the concepts being discussed. Use analogies and metaphors to help explain complex concepts in a way that is easy to understand. Provide step-by-step instructions for any code examples or exercises. Encourage the reader to experiment with the code and try different variations to see how it works. Provide resources for further learning and exploration of the topics being discussed.

Choose the appropriate technology that we can demonstrate with minimum dependencies and minimum setup. The technology should be easy to learn and easy to use. The technology should be widely used and well supported. The technology should be suitable for the concepts being discussed. The technology should be easy to integrate with other tools and technologies. The technology should be easy to deploy and easy to scale. The technology should be easy to maintain and easy to update. The technology should be easy to learn and easy to teach. The technology should be easy to share and easy to collaborate on. The technology should be easy to use and easy to integrate with other tools and technologies.

Before implementing educational resources, please research and understand the concepts being discussed using browser and reading as much docs as possible. Make sure you have a good understanding of the concepts before trying to explain them to others. Use reliable sources and references to ensure the accuracy of the information being presented. Test the code examples and exercises to ensure they work as expected. Make sure the code is well commented and well documented to help others understand it. Be open to feedback and suggestions for improvement from others who may have more experience or knowledge in the topics being discussed. Continuously update and improve the educational resources based on feedback and new developments in the field.

For anything require docker like postgres or redis, please use docker compose to set up the environment. Provide clear instructions on how to set up and run the docker containers. Make sure the docker compose file is well documented and easy to understand. Provide examples of how to connect to the services running in the docker containers from the code examples. Encourage the reader to experiment with the docker setup and try different configurations to see how it works. Provide resources for further learning and exploration of docker and containerization concepts.

When creating an educational resource make sure its working run it yourself and test it before sharing it. Make sure the code is well commented and well documented to help others understand it. Provide clear instructions on how to run the code examples and exercises. Make sure the code is easy to understand and easy to follow. Encourage the reader to experiment with the code and try different variations to see how it works. Provide resources for further learning and exploration of the topics being discussed.

When creating backend educational resources, please follow these guidelines to ensure clarity and ease of understanding for beginners:
- Use a simple and widely adopted backend framework like fastapi.
- Use pydantic or similar libraries for data validation and serialization.


When creating educational resources that involve real-time data or databases, consider incorporating visualization tools to help users better understand the concepts being demonstrated. Here are some suggestions:
RedisInsight for Redis: A graphical tool that allows users to visualize and manage their Redis databases. It provides features like real-time monitoring, query analysis, and data exploration.
Adminer for postgres

When creating Jupyter notebooks, always include setup instructions for the virtual environment and kernel selection:
- Each lab folder should have its own `.venv` managed by uv
- Dependencies are installed via `uv sync`
- The notebook setup cell must instruct the user to select the `.venv` kernel in VS Code's kernel picker (top-right of the notebook)
- If the kernel doesn't appear, advise the user to reload the VS Code window (`Cmd+Shift+P` → "Reload Window")
