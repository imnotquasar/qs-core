export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  accent?: string;
  glow?: string;
  border?: string;
}

export interface Vehicle {
  plate: string;
  model: string;
  state: number;
  fuel: number;
  engine: number;
  body: number;
  props?: unknown;
}

export interface GarageData {
  label: string;
  vehicles: Vehicle[];
}

export type Locale = Record<string, string>;
