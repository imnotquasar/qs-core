export interface Category {
  key: string;
  label: string;
  kind: 'component' | 'prop' | 'overlay' | 'tattoo' | 'eyecolor';
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

export interface Heritage {
  father: number;
  mother: number;
  shape: number;
  skin: number;
}

export interface Parent {
  id: number;
  name: string;
}

export interface Feature {
  key: string;
  label: string;
}

export type Skin = {
  sex?: string;
  heritage?: Heritage;
  features?: number[];
  [key: string]: SkinEntry | Heritage | number[] | string | undefined;
};

export interface OpenData {
  categories: Category[];
  sections?: Section[];
  fathers?: Parent[];
  mothers?: Parent[];
  features?: Feature[];
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
