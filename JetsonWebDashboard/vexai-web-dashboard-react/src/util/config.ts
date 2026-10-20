import { images } from "./images";
import { Element } from "../lib/types";

/**
 * General configuration for the application
 */
export const config = {
  socketIP: "10.42.0.1",
  socketPort: "3030",

  /**
   * Default image width captured by the camera on the robot
   */
  SCALE_X: 640,

  /**
   * Default image height captured by the camera on the robot
   */
  SCALE_Y: 480,

  /**
   * Rate at which the data services polls for data (ms)
   */
  pollingInterval: 60,
  logDataResponse: true,
  detectOutOfBoundsElements: true,
  colors: {
    red: "#D22630",
    darkRed: "#971c22",
    gray: "#939597",
    darkGray: "#58585B",
    darkerGray: "#111111",
    blue: "#0077C8",
    darkBlue: "#004d80",
    black: "#000000",
    white: "#F4F2FF",
    orange: "#fca503",
    darkOrange: "#bf7e04",
    purple: "#7466F1",
    darkPurple: "#433b87",
    grayPurple: "#293045",
  },
  field: {
    dimension: 3.6576, // meters
    oov: 0.1,
    texture: images.field,
    scale: 1.0,
    compass: {
      texture: images.map.compass,
      scale: 0.23,
      ringPositionCorrectionX: 0.1,
      lineScale: 0.03,
      numberOffset: 0.045,
      numberScale: 0.017,
    },
    fog: {
      opacity: 0.75,
    },
    ruler: {
      texture: images.map.ruler,
      xySidebarOffset: 0.26,
      xySidebarMarkersOffset: 0.22,
      xySidebarArrowOffset: 0.22,
      xySidebarSizeMultiplier: 0.025,
      arrowScale: 0.1,
    },
    robot: {
      length: 0.4191, // meters
      width: 0.3175, // meters
      scale: 2,
      texture: images.robot,
      textureWidth: 1600, // pixels
      textureHeight: 1600, // pixels
      fov: 50,
    },
  },
  elements: 
    [
      {
        label: "RedBluePin",
        backgroundColor: "rgba(255, 0, 255, 0.3)",
        size: {
          height: 0.04064,
          width: 0.04064,
          scale: 6,
        },
        texture: {
          vertical: images.elements.redBluePin,
        },
        zIndex: 1
      },
      {
        label: "BlueYellowPin",
        backgroundColor: "rgba(0, 0, 255, 0.3)",
        size: {
          height: 0.04064,
          width: 0.04064,
          scale: 6,
        },
        texture: {
          horizontal: images.elements.blueYellowPin.horizontal,
          vertical: images.elements.blueYellowPin.vertical,
        },
        zIndex: 1
      },
      {
        label: "RedYellowPin",
        backgroundColor: "rgba(255, 0, 0, 0.3)",
        size: {
          height: 0.04064,
          width: 0.04064,
          scale: 6,
        },
        texture: {
          horizontal: images.elements.redYellowPin.horizontal,
          vertical: images.elements.redYellowPin.vertical,
        },
        zIndex: 1
      },
      {
        label: "YellowPin",
        backgroundColor: "rgba(255, 217, 0, 0.3)",
        size: {
          height: 0.04064,
          width: 0.04064,
          scale: 4,
        },
        texture: images.elements.yellowPin.vertical,
        zIndex: 1
      },
      {
        label: "Cup",
        backgroundColor: "rgba(211, 211, 211, 0.3)",
        size: {
          height: 0.08001,
          width: 0.08001,
          scale: 3,
        },
        texture: images.elements.cup,
        zIndex: 0
      },
    ] as Element[],
};
