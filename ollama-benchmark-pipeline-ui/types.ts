export enum ItemStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  FAILED = 'failed',
  PROCESSING = 'processing'
}

export interface DetectionResult {
  box_2d: number[];
  label: string;
  confidence: number;
}

export interface PipelineItem {
  id: string;
  filename: string;
  filepath: string;
  thumbnailUrl: string; // Mock URL
  status: ItemStatus;
  timestamp: string;
  description: string;
  metadata: {
    width: number;
    height: number;
    camera_model?: string;
    iso?: number;
  };
  detection_raw?: {
    model: string;
    objects: DetectionResult[];
  };
  processingTimeMs?: number;
  source: 'Ollama' | 'Gemini' | 'Manual';
}

export interface PipelineStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
  avgProcessingTime: number;
  uptime: string;
}

export interface SystemConfig {
  ollamaUrl: string;
  model: string;
  useGeminiFallback: boolean;
  geminiApiKey: string;
  autoApproveConfidence: number;
  watchPath: string;
  outputPath: string;
}
