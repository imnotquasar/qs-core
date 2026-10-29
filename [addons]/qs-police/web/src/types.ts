export interface ArmoryItem {
  name: string;
  label: string;
  count: number;
}

export interface SearchItem {
  slot: number;
  name: string;
  label: string;
  count: number;
  info?: Record<string, any>;
}

export interface LabItem {
  slot: number;
  info: Record<string, any>;
}

export interface GarageVehicle {
  model: string;
  label: string;
}

export interface UIData {
  mode: 'armory' | 'search' | 'lab' | 'garage';
  name?: string;
  items?: any[];
  vehicles?: GarageVehicle[];
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
