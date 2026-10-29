export type NotifyType = 'success' | 'error' | 'info' | 'primary';

export interface NotifyData {
  message: string;
  title?: string;
  type?: NotifyType;
  duration?: number;
}

export interface Toast extends NotifyData {
  id: number;
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
