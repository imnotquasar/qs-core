export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  accent?: string;
  glow?: string;
  border?: string;
}

export interface Vehicle {
  model: string;
  label: string;
  price: number;
}

export interface Category {
  id: string;
  label: string;
}

export interface ShopData {
  categories: Category[];
  vehicles: Record<string, Vehicle[]>;
  cash: number;
  bank: number;
}

export type Locale = Record<string, string>;
