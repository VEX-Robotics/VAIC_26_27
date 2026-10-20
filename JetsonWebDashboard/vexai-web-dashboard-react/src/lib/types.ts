export enum ElementType {
  RedBluePin = 0,
  BlueYellowPin = 1,
  RedYellowPin = 2,
  YellowPin = 3,
  Cup = 4
}

export interface Element {
  texture?: string | {
    vertical: string;
    horizontal: string;
  };
  size?: {
    width: number;
    height: number;
    scale: number;
  },
  zIndex?: number;
  borderColor?: string;
  backgroundColor?: string;
  label?: string;
}

export enum Direction {
  X = 0,
  Y = 1,
}

export interface Theme {
  id: string;
  componentBackground: string;
  font: string;
  control: string;
  controlHover: string;
}
