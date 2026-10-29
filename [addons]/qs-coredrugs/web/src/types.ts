export interface DrugItem {
  key: string;
  name: string;
  label: string;
  price: number;
  count: number;
}

export interface DealerData {
  items: DrugItem[];
  black: number;
  limit?: number;
  sold?: number;
}

export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  primaryDim?: string;
  accent?: string;
  gradientFrom?: string;
  gradientTo?: string;
  glow?: string;
  border?: string;
  panel?: string;
  health?: string;
  armor?: string;
  hunger?: string;
  thirst?: string;
}
