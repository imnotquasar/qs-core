export interface Colors {
  text?: string;
  muted?: string;
  primary?: string;
  accent?: string;
  glow?: string;
  border?: string;
}

export interface Transaction {
  type: string;
  amount: number;
  balance: number;
  label?: string;
  created?: string;
}

export interface BankData {
  mode: 'bank' | 'atm';
  cash: number;
  bank: number;
  account: string;
  history: Transaction[];
}

export type Locale = Record<string, string>;
