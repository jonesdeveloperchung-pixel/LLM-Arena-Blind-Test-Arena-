import { BenchmarkCategory } from './types';
import { Brain, Code, Eye, MessageSquare, Database } from 'lucide-react';

export const CATEGORIES = [
  {
    id: BenchmarkCategory.REASONING,
    icon: Brain,
    label: 'Reasoning',
    description: 'Multi-hop logic, math word problems, and complex planning.',
    metrics: ['Accuracy', 'Step Clarity', 'Consistency'],
    promptType: 'text',
  },
  {
    id: BenchmarkCategory.CODING,
    icon: Code,
    label: 'Coding',
    description: 'Code generation, debugging, and algorithmic explanation.',
    metrics: ['Correctness', 'Efficiency', 'Readability'],
    promptType: 'text',
  },
  {
    id: BenchmarkCategory.VISION,
    icon: Eye,
    label: 'Vision',
    description: 'Image description and visual reasoning.',
    metrics: ['Accuracy', 'Interpretation Depth', 'Alignment'],
    promptType: 'image',
  },
  {
    id: BenchmarkCategory.GENERAL,
    icon: MessageSquare,
    label: 'General Lang',
    description: 'Fluency, creative writing, and summarization.',
    metrics: ['Fluency', 'Coherence', 'Creativity'],
    promptType: 'text',
  },
  {
    id: BenchmarkCategory.EMBEDDING,
    icon: Database,
    label: 'Embedding',
    description: 'Semantic similarity and retrieval relevance checks.',
    metrics: ['Relevance', 'Discrimination', 'Semantic Grasp'],
    promptType: 'text',
  },
];

export const INITIAL_RADAR_DATA = CATEGORIES.map((c) => ({
  subject: c.label,
  A: 0,
  fullMark: 5,
}));
