export interface ChatMessage {
  id?: number;
  author?: string;
  text: string;
  time?: string;
  type?: 'player' | 'system' | 'me' | 'do' | 'ooc' | 'b' | 'pm';
}

export interface SugParam {
  name: string;
  help?: string;
}

export interface Suggestion {
  name: string;
  help?: string;
  params?: SugParam[];
}

export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  primaryDim?: string;
  accent?: string;
  glow?: string;
  border?: string;
}
