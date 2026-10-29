export interface ShowData {
  serverId: number;
  job: string;
  cash: number;
  bank: number;
  online: number;
  max: number;
}

export interface CountsData {
  online: number;
  max: number;
}

export interface VehData {
  speed: number;
  rpm: number;
  gear: number;
  fuel: number;
  engine: number;
  belt: boolean;
  street: string;
  unit: string;
}

export interface StatusData {
  health: number;
  armor: number;
  hunger: number;
  thirst: number;
  stamina: number;
  talking: boolean;
  voicemode: number;
}

export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  primaryDim?: string;
  accent?: string;
  glow?: string;
  border?: string;
  panel?: string;
  health?: string;
  armor?: string;
  hunger?: string;
  thirst?: string;
}
