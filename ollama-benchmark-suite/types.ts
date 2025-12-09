export enum BenchmarkCategory {
  REASONING = 'Reasoning',
  CODING = 'Coding',
  VISION = 'Vision-Language',
  GENERAL = 'General Language',
  EMBEDDING = 'Embedding Capability',
}

export interface BenchmarkResult {
  category: BenchmarkCategory;
  score: number; // 1-5
  feedback: string;
  metrics: Record<string, number | string>;
  testCase: string;
  modelOutput: string;
}

export interface TestCase {
  prompt: string;
  imageUri?: string; // For vision tasks
  imageBase64?: string;
  expectedAspects: string[];
}

export interface EvaluationResponse {
  score: number;
  reasoning: string;
  breakdown: {
    [key: string]: number; // Sub-metric scores (e.g., accuracy: 5)
  };
}
