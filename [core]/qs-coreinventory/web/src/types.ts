export interface InvItem {
  name: string;
  label: string;
  count: number;
  weight: number;
  useable: boolean;
  description?: string;
  image?: string;
  max: number;

  info?: Record<string, unknown>;
}

export type Slot = InvItem | false | null;

export type Container = 'player' | 'secondary';

export interface Section {
  slots: number;
  columns: number;
  items: Slot[];
  weight: number;
  maxWeight: number;
  label?: string;

  kind?: string;
}

export interface InvData extends Section {
  secondary?: Section;
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
