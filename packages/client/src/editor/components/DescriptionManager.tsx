import React from "react";
import { Input } from "./FormComponents";

interface Description {
  key: number;
  text: string;
}

interface DescriptionEditorProps {
  value: Description[];
  onChange: (updated: Description[]) => void;
}

export const DescriptionEditor: React.FC<DescriptionEditorProps> = ({
  value,
  onChange,
}) => {
  const handleTextChange = (index: number, newText: string) => {
    const updated = [...value];
    updated[index].text = newText;
    onChange(updated);
  };

  const handleAdd = () => {
    const nextKey = value.length > 0 ? value[value.length - 1].key + 1 : 0;
    onChange([...value, { key: nextKey, text: "" }]);
  };

  const handleRemove = (index: number) => {
    const updated = [...value];
    updated.splice(index, 1);
    onChange(updated);
  };

  return (
    <div>
      <label>Descriptions</label>
      <div className="flex min-h-[60px] w-full flex-col space-y-1.5">
        {value.map((desc, index) => (
          <div key={desc.key} className="flex gap-1.5 items-center">
            <Input
              id={`description_text_${desc.key}`}
              value={desc.text}
              onChange={(e) => handleTextChange(index, e.target.value as string)}
            />
            <span className="w-10 text-center text-sm text-gray-500">Key: {desc.key}</span>
            <button
              type="button"
              className="text-red-500 hover:text-red-700"
              onClick={() => handleRemove(index)}
            >
              ✕
            </button>
          </div>
        ))}
      </div>
      <button
        type="button"
        onClick={handleAdd}
        className="mt-2 px-2 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
      >
        Add Description
      </button>
    </div>
  );
};