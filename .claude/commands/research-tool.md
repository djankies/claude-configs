---
description: Research a tool
argument-hint: <tool-name-with-major-version> (e.g., "react-19")
allowed-tools: Task, Read
---

Your Task is to:

1. Call the `tool-research-specialist` sub-agent to super deep dive research it this tool: $ARGUMENTS.

example sub-agent prompt:

```text
Please research this tool: [tool_name]
version: [version] (use package.json version if not provided)
Save the research to the `$ARGUMENTS/RESEARCH.md` file.
filename format: MM-DD-YYYY-<tool_name>-<version>.md
```

2. Validate that the sub-agent will generate a research document located at `@$ARGUMENTS/RESEARCH.md` file.
