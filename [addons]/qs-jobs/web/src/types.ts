export interface CenterJob {
  key: string;
  label: string;
  salary: number;
}

export interface CenterData {
  jobs: CenterJob[];
  current: string;
}

export interface ShiftData {
  on: boolean;
  done?: number;
  total?: number;
  earned?: number;
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
