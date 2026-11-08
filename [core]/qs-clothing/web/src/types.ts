export interface Category {
  key: string;
  label: string;
  kind: 'component' | 'prop' | 'overlay' | 'tattoo';
  id?: number;
  max: number;
  section?: string;
}

export interface Section {
  key: string;
  label: string;
}

export interface SkinEntry {
  drawable: number;
  texture: number;
}

export type Skin = Record<string, SkinEntry | string | undefined> & { sex?: string };

export interface OpenData {
  categories: Category[];
  sections?: Section[];
  skin: Skin;
  creator?: boolean;
  defaultSection?: string;
  disabled?: string[];
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
}
