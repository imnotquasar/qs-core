import { useEffect, useState } from 'react';
import type { IconType } from 'react-icons';
import {
  FaBox,
  FaTint,
  FaBreadSlice,
  FaMobileAlt,
  FaIdCard,
  FaBriefcaseMedical,
  FaHamburger,
  FaMugHot,
  FaBolt,
  FaWineBottle,
  FaHatCowboy,
} from 'react-icons/fa';
import { GiPistolGun, GiSandwich, GiWaterBottle } from 'react-icons/gi';
import type { InvItem } from './types';

const ICONS: Record<string, IconType> = {
  water: FaTint,
  bread: FaBreadSlice,
  phone: FaMobileAlt,
  id_card: FaIdCard,
  bandage: FaBriefcaseMedical,
  burger: FaHamburger,
  sandwich: GiSandwich,
  cola: FaWineBottle,
  coffee: FaMugHot,
  energy_drink: FaBolt,
  water_bottle: GiWaterBottle,
  weapon_pistol: GiPistolGun,
  hat: FaHatCowboy,
};

const EXTS = ['png', 'svg'];

export default function ItemImg({ item }: { item: InvItem }) {
  const [stage, setStage] = useState(0);
  useEffect(() => setStage(0), [item.name, item.image]);
  if (!item.image && stage >= EXTS.length) {
    const Icon = ICONS[item.name] || FaBox;
    return <Icon className="slot-ico" />;
  }
  const src = item.image || `../images/${item.name}.${EXTS[stage]}`;
  return <img className="slot-img" src={src} onError={() => setStage((s) => s + 1)} alt="" draggable={false} />;
}
