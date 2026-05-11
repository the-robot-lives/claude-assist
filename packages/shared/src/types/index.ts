// Conversation source record types (from JSONL)
export type RecordType =
  | "permission-mode"
  | "user"
  | "assistant"
  | "attachment"
  | "system"
  | "file-history-snapshot"
  | "last-prompt"
  | "queue-operation"
  | "custom-title"
  | "agent-name";

export interface BaseRecord {
  uuid: string;
  parentUuid: string | null;
  type: RecordType;
  timestamp: string;
  sessionId: string;
  isSidechain?: boolean;
}

export interface UserMessage extends BaseRecord {
  type: "user";
  message: {
    role: "user";
    content: string | ContentBlock[];
  };
  promptId?: string;
  permissionMode?: string;
  cwd?: string;
  version?: string;
  gitBranch?: string;
}

export interface ContentBlock {
  type: "text" | "tool_result" | "tool_use" | "thinking";
  text?: string;
  thinking?: string;
  tool_use_id?: string;
  content?: string;
  is_error?: boolean;
  id?: string;
  name?: string;
  input?: Record<string, unknown>;
}

export interface AssistantMessage extends BaseRecord {
  type: "assistant";
  message: {
    model: string;
    role: "assistant";
    content: ContentBlock[];
    stop_reason: string | null;
    usage?: TokenUsage;
  };
}

export interface TokenUsage {
  input_tokens: number;
  output_tokens: number;
  cache_creation_input_tokens?: number;
  cache_read_input_tokens?: number;
}

// Index database types
export interface Conversation {
  id: string;
  projectPath: string;
  startedAt: Date;
  updatedAt: Date;
  messageCount: number;
  title: string;
  slug: string | null;
  description: string | null;
  summary: string | null;
  tags: string[];
  status: "active" | "archived" | "edited";
  sourcePath: string;
}

export interface SearchResult {
  conversation: Conversation;
  snippet: string;
  highlights: Array<{ start: number; end: number }>;
  relevance: number;
}

export interface SearchOptions {
  query: string;
  mode: "fts" | "semantic";
  project?: string;
  dateFrom?: Date;
  dateTo?: Date;
  role?: "user" | "assistant" | "tool";
  limit?: number;
  offset?: number;
}

// Thread editing
export interface ThreadEdit {
  id: string;
  sourceId: string;
  createdAt: Date;
  description: string;
  messages: EditedMessage[];
}

export interface EditedMessage {
  originalIndex?: number;
  role: "user" | "assistant" | "system";
  content: string;
  injected?: boolean;
  collapsed?: boolean;
}

// Conversion artifacts
export type ArtifactType = "agent" | "skill" | "command" | "snippet" | "runbook";

export interface ConversionCandidate {
  type: ArtifactType;
  startIndex: number;
  endIndex: number;
  confidence: number;
  description: string;
}

export interface Artifact {
  type: ArtifactType;
  name: string;
  description: string;
  content: string;
  sourceConversationId: string;
  sourceMessageRange: [number, number];
}

// Dataset types
export type QualityLabel = "gold" | "silver" | "bronze";

export interface Dataset {
  name: string;
  description: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  entryCount: number;
}

export interface DatasetEntry {
  id: string;
  datasetName: string;
  conversationId: string;
  editId?: string;
  startIndex: number;
  endIndex: number;
  quality: QualityLabel;
  systemPrompt?: string;
  messages: Array<{ role: string; content: string }>;
  createdAt: Date;
}

// API response wrappers
export interface ApiResponse<T> {
  data: T;
  meta?: {
    total?: number;
    page?: number;
    limit?: number;
  };
}

export interface ApiError {
  error: string;
  code: string;
  details?: Record<string, unknown>;
}

// Config
export type LlmProvider =
  | "anthropic"
  | "openai"
  | "ollama"
  | "litellm"
  | "groq"
  | "cerebras"
  | "deepseek"
  | "zai"
  | "custom";

export interface LlmConfig {
  provider: LlmProvider;
  model?: string;
  apiKey?: string;
  baseUrl?: string;
  apiType?: "openai" | "anthropic";
}

export interface AppConfig {
  indexPaths: string[];
  embedding: {
    provider: "local" | "openai" | "voyage" | "anthropic";
    model?: string;
    apiKey?: string;
  };
  llm?: LlmConfig;
  server: {
    port: number;
    host: string;
  };
}

// LLM inference
export interface LlmCompletionRequest {
  messages: Array<{ role: "system" | "user" | "assistant"; content: string }>;
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface LlmCompletionResponse {
  content: string;
  model: string;
  provider: string;
  usage?: {
    inputTokens: number;
    outputTokens: number;
  };
  finishReason: string;
}
