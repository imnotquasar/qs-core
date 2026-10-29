export interface CharInfo {
  firstname?: string;
  lastname?: string;
  dob?: string;
  nationality?: string;
  sex?: string;
}

export interface Character {
  citizenid: string;
  charinfo?: CharInfo;
  money?: { cash?: number; bank?: number };
  job?: { name?: string; label?: string };
}

export interface SetCharactersData {
  characters: Character[];
  maxSlots: number;
}

export interface Loc {
  select_title: string;
  create_title: string;
  create_subtitle: string;
  create_slot: string;
  civilian: string;
  firstname: string;
  lastname: string;
  dob: string;
  nationality: string;
  sex: string;
  male: string;
  female: string;
  day: string;
  month: string;
  year: string;
  back: string;
  create: string;
  select: string;
  play: string;
  delete: string;
  settings: string;
  quit: string;
  pose: string;
  delete_confirm: string;
  confirm_delete_msg: string;
  confirm_quit_msg: string;
  confirm_yes: string;
  confirm_no: string;
  months: string[];
  err_invalid_input: string;
  err_max_characters: string;
  err_no_license: string;
  err_not_found: string;
  err_not_owner: string;
}

export interface OpenData {
  brand: string;
  t: Loc;
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
