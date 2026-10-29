export interface ShopItem {
  name: string;
  label: string;
  price: number;
  weight?: number;
  image?: string;
}

export interface ShopData {
  name: string;
  label: string;
  items: ShopItem[];
  cash: number;
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
