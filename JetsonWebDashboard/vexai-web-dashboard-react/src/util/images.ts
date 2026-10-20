import VexAILogoBlack from "../images/vex_ai_logo_black.png";
import VexAILogoWhite from "../images/vex_ai_logo_white.png";
import Robot from "../images/HeroBot-Top.png";
import Field from "../images/FieldTopDown-Cleared.png";
import Compass from "../images/compass.png";
import Ruler from "../images/ruler.png";
import RedBluePinVertical from "../images/BlueRedPin-Vertical.png"
import RedYellowPinVertical from "../images/RedYellowPin-Vertical.png"
import RedYellowPinHorizontal from "../images/RedYellowPin-Horizontal.png"
import BlueYellowPinVertical from "../images/BlueYellowPin-Vertical.png"
import BlueYellowPinHorizontal from "../images/BlueYellowPin-Horizontal.png"
import YellowPinVertical from "../images/YellowPin-Vertical.png"
import CupVertical from "../images/Cup-Vertical.png"

export const images = {
  icons: {},
  logos: {
    vexAILogoBlack: VexAILogoBlack,
    vexAILogoWhite: VexAILogoWhite,
  },
  map: {
    compass: Compass,
    ruler: Ruler,
  },
  elements: {
    redBluePin:         RedBluePinVertical,
    redYellowPin:       { vertical: RedYellowPinVertical,  horizontal: RedYellowPinHorizontal  },
    blueYellowPin:      { vertical: BlueYellowPinVertical, horizontal: BlueYellowPinHorizontal },
    yellowPin:          { vertical: YellowPinVertical },
    cup:                CupVertical 
  },
  robot: Robot,
  field: Field,
};
