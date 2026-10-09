import type { E2EConfig } from 'e2e';
import { web } from '@e2e-dev/web';
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

// Any OpenAI-compatible endpoint with TWO distinct tool-capable models works.
// Verified setups (2026-10-09):
//   - https://agent-gw.kimi.com/coding/v1  models: k3-agent / k2d8-preview  (env: KIMI_API_KEY)
//   - https://api.kimi.com/coding/v1       models: k3 / kimi-for-coding
// Override all three below for your own provider.
const provider = createOpenAICompatible({
  name: 'llm',
  baseURL: process.env.LLM_BASE_URL!,
  apiKey: process.env.LLM_API_KEY!,
});

export default {
  targets: [{ engine: web(), app: { url: 'http://localhost:4173' } }],
  agents: {
    // Model id is read from the environment on purpose: experiment B swaps the
    // model under the SAME agent, which is exactly what the cache key ignores.
    default: { model: provider.chatModel(process.env.E2E_MODEL ?? 'model-a') },
    b: { model: provider.chatModel(process.env.E2E_MODEL_B ?? 'model-b') },
  },
} satisfies E2EConfig;
