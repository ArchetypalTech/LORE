# LORE Designer Model Context Protocol (MCP) Architecture

https://modelcontextprotocol.io/
https://www.youtube.com/watch?v=HyzlYwjoXOQ

## Overview

The Model Context Protocol (MCP) implementation for the LORE designer system provides a standardized way to connect AI models to our smart contract data and tools. This architecture enables LLMs to interact with our designer system through a client-server model, where the MCP server exposes our contract capabilities in a standardized way.

## Core Architecture

### Components

#### MCP Host

- The LORE application that wants to access designer data through MCP
- Can be our web interface, CLI tools, or other applications
- Maintains connections to MCP servers

#### MCP Server

A lightweight program that exposes our designer contract capabilities through the standardized MCP protocol:

```typescript
interface IDesignerMCPServer {
  // Resources - Expose contract data to LLMs
  resources: {
    entities: Resource<Entity[]>;
    inspectables: Resource<Inspectable[]>;
    areas: Resource<Area[]>;
    exits: Resource<Exit[]>;
    parentRelations: Resource<ParentToChildren[]>;
    childRelations: Resource<ChildToParent[]>;
  };

  // Tools - Enable LLMs to perform actions
  tools: {
    createEntity: Tool<Entity[], Result>;
    deleteEntity: Tool<string[], Result>;
    createInspectable: Tool<Inspectable[], Result>;
    deleteInspectable: Tool<string[], Result>;
    createArea: Tool<Area[], Result>;
    deleteArea: Tool<string[], Result>;
    createExit: Tool<Exit[], Result>;
    deleteExit: Tool<string[], Result>;
    createParentRelation: Tool<ParentToChildren[], Result>;
    deleteParentRelation: Tool<string[], Result>;
    createChildRelation: Tool<ChildToParent[], Result>;
    deleteChildRelation: Tool<string[], Result>;
  };

  // Prompts - Reusable prompt templates
  prompts: {
    entityCreation: Prompt;
    entityDeletion: Prompt;
    relationshipManagement: Prompt;
    errorHandling: Prompt;
  };
}
```

#### Local Data Sources

- The `designer.cairo` smart contract
- Local state management
- Transaction history
- User preferences

#### Remote Services

- Blockchain network connection
- External APIs (if needed)
- Authentication services

## Implementation Details

### Server Implementation

```typescript
class DesignerMCPServer implements MCPServer {
  // Resource Handlers
  async getEntities(): Promise<Resource<Entity[]>> {
    // Fetch entities from contract
    return new Resource(entities, {
      refresh: async () => {
        /* Update logic */
      },
      validate: (data) => {
        /* Validation logic */
      },
    });
  }

  // Tool Handlers
  async createEntityTool(input: Entity[]): Promise<ToolResult> {
    try {
      // Contract interaction
      const result = await this.contract.create_entity(input);
      return {
        success: true,
        data: result,
      };
    } catch (error) {
      return {
        success: false,
        error: this.formatError(error),
      };
    }
  }

  // Prompt Templates
  getEntityCreationPrompt(): Prompt {
    return new Prompt({
      template: `Create a new entity with the following properties:
        {properties}
        Validate the input and provide appropriate feedback.`,
      variables: ["properties"],
    });
  }
}
```

### Client Implementation

```typescript
class DesignerMCPClient implements MCPClient {
  private server: MCPServer;

  async connect(serverUrl: string): Promise<void> {
    this.server = await MCPClient.connect(serverUrl);
  }

  async executeTool<T>(toolName: string, input: any): Promise<ToolResult<T>> {
    return this.server.executeTool(toolName, input);
  }

  async getResource<T>(resourceName: string): Promise<Resource<T>> {
    return this.server.getResource<T>(resourceName);
  }
}
```

## Integration Flow

1. **Resource Access Flow**:

```
LLM Request → MCP Client → MCP Server → Contract → Resource Response
```

2. **Tool Execution Flow**:

```
LLM Request → MCP Client → MCP Server → Contract → Transaction → Result
```

## Security Considerations

1. **Data Access**:

   - MCP server runs in a secure environment
   - Contract interactions are properly authenticated
   - Resource access is controlled and validated

2. **Tool Execution**:

   - All tool inputs are validated
   - Transaction signing is handled securely
   - Error handling and rollback mechanisms

3. **Prompt Security**:
   - Prompt templates are validated
   - Input sanitization
   - Output validation

## Testing Strategy

1. **Unit Testing**:

   - Resource handlers
   - Tool implementations
   - Prompt templates

2. **Integration Testing**:

   - MCP client-server communication
   - Contract interaction
   - End-to-end workflows

3. **Security Testing**:
   - Access control
   - Input validation
   - Error handling

## Development Guidelines

1. **Server Development**:

   - Implement MCP server interface
   - Define resources and tools
   - Create prompt templates
   - Handle errors and validation

2. **Client Development**:

   - Implement MCP client interface
   - Handle server connections
   - Manage resource updates
   - Execute tools safely

3. **Prompt Engineering**:
   - Design reusable templates
   - Include validation rules
   - Provide clear error messages
   - Document usage examples

## Future Considerations

1. **Scalability**:

   - Multiple server instances
   - Resource caching
   - Batch operations

2. **Extensibility**:

   - New resource types
   - Additional tools
   - Custom prompt templates

3. **Monitoring**:
   - Performance metrics
   - Usage statistics
   - Error tracking
