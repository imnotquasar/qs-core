export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  accent?: string;
  glow?: string;
  border?: string;
}

export interface Player {
  id: number;
  name: string;
  job: string;
  grade?: string | number;
  ping: number;
  cash?: number;
  bank?: number;
}

export interface States {
  godmode?: boolean;
  invisible?: boolean;
  noclip?: boolean;
}

export interface OpenData {
  weathers: string[];
  groups: string[];
  states: States;
}

export type Locale = Record<string, string>;
