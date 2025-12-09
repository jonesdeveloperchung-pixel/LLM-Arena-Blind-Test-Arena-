import { PipelineItem, ItemStatus, PipelineStats } from '../types';

// Helper to generate mock data
const generateMockItems = (count: number): PipelineItem[] => {
  const items: PipelineItem[] = [];
  const statuses = [ItemStatus.PENDING, ItemStatus.APPROVED, ItemStatus.REJECTED, ItemStatus.FAILED];
  
  for (let i = 0; i < count; i++) {
    const isPending = i < 5; // First 5 are pending
    items.push({
      id: `task_${Date.now()}_${i}`,
      filename: `IMG_${20240000 + i}.jpg`,
      filepath: `/input/IMG_${20240000 + i}.jpg`,
      thumbnailUrl: `https://picsum.photos/400/300?random=${i}`,
      status: isPending ? ItemStatus.PENDING : statuses[Math.floor(Math.random() * statuses.length)],
      timestamp: new Date(Date.now() - i * 3600000).toISOString(),
      description: `這是一張由 Ollama 模型生成的範例描述。圖片包含了一些自然的風景和物體。 (Sample description ${i})`,
      metadata: {
        width: 1920,
        height: 1080,
        camera_model: "Sony A7IV",
        iso: 100 * (i + 1)
      },
      detection_raw: {
        model: "llama3.2-vision",
        objects: [
          { box_2d: [100, 100, 200, 200], label: "person", confidence: 0.95 },
          { box_2d: [300, 300, 500, 500], label: "car", confidence: 0.88 }
        ]
      },
      processingTimeMs: 1200 + Math.random() * 2000,
      source: 'Ollama'
    });
  }
  return items;
};

let mockStore = generateMockItems(20);

export const mockBackend = {
  getItems: async (): Promise<PipelineItem[]> => {
    return new Promise((resolve) => {
      setTimeout(() => resolve([...mockStore]), 500);
    });
  },

  updateItemStatus: async (id: string, status: ItemStatus, description?: string): Promise<PipelineItem | null> => {
    return new Promise((resolve) => {
      setTimeout(() => {
        const index = mockStore.findIndex(i => i.id === id);
        if (index !== -1) {
          mockStore[index] = { 
            ...mockStore[index], 
            status, 
            description: description || mockStore[index].description,
            source: description ? 'Manual' : mockStore[index].source
          };
          resolve(mockStore[index]);
        } else {
          resolve(null);
        }
      }, 300);
    });
  },

  getStats: async (): Promise<PipelineStats> => {
    return new Promise((resolve) => {
      const stats: PipelineStats = {
        total: mockStore.length,
        pending: mockStore.filter(i => i.status === ItemStatus.PENDING).length,
        approved: mockStore.filter(i => i.status === ItemStatus.APPROVED).length,
        rejected: mockStore.filter(i => i.status === ItemStatus.REJECTED).length,
        avgProcessingTime: 1850,
        uptime: "2d 4h 12m"
      };
      resolve(stats);
    });
  }
};
