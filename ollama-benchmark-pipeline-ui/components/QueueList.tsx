import React from 'react';
import { PipelineItem, ItemStatus } from '../types';
import { Eye, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

interface QueueListProps {
  items: PipelineItem[];
  onSelectItem: (item: PipelineItem) => void;
  filter: ItemStatus | 'all';
}

const QueueList: React.FC<QueueListProps> = ({ items, onSelectItem, filter }) => {
  const filteredItems = filter === 'all' ? items : items.filter(i => i.status === filter);

  const getStatusBadge = (status: ItemStatus) => {
    switch (status) {
      case ItemStatus.PENDING:
        return <span className="px-2 py-1 text-xs font-semibold bg-yellow-100 text-yellow-700 rounded-full">待審核</span>;
      case ItemStatus.APPROVED:
        return <span className="px-2 py-1 text-xs font-semibold bg-green-100 text-green-700 rounded-full">已核准</span>;
      case ItemStatus.REJECTED:
        return <span className="px-2 py-1 text-xs font-semibold bg-red-100 text-red-700 rounded-full">已駁回</span>;
      case ItemStatus.FAILED:
        return <span className="px-2 py-1 text-xs font-semibold bg-gray-100 text-gray-700 rounded-full">失敗</span>;
      default:
        return null;
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">縮圖 (Preview)</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">檔案名稱 (Filename)</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">模型 (Model)</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">狀態 (Status)</th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">時間 (Time)</th>
              <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">操作 (Actions)</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredItems.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-gray-400">
                  <div className="flex flex-col items-center">
                    <AlertCircle size={32} className="mb-2" />
                    <p>沒有資料 (No items found)</p>
                  </div>
                </td>
              </tr>
            ) : (
              filteredItems.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <img src={item.thumbnailUrl} alt={item.filename} className="h-12 w-16 object-cover rounded-md border border-gray-200" />
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{item.filename}</div>
                    <div className="text-xs text-gray-500">{item.id}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {item.detection_raw?.model || 'Unknown'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(item.status)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(item.timestamp).toLocaleTimeString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button 
                      onClick={() => onSelectItem(item)}
                      className="text-blue-600 hover:text-blue-900 flex items-center justify-end gap-1 ml-auto"
                    >
                      <Eye size={16} />
                      檢視
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default QueueList;
