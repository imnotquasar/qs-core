export interface RegionState {
  type: string;
  level: number;
  pct: number;
}

export interface TreatItem {
  name: string;
  injury: string;
  count: number;
}

export interface OpenData {
  name: string;
  downed: boolean;
  regions: Record<string, RegionState>;
  items: TreatItem[];
}

export interface RegionPos {
  x: number;
  y: number;
  on: boolean;
}

export type Positions = Record<string, RegionPos>;

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
