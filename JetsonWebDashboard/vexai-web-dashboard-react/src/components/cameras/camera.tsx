import React, { RefObject, useEffect, useRef, useState } from "react";
import { Box, IconButton, Tooltip } from "@mui/material";
import ConnectingToCameraProgress from "./connecting-to-camera-progress";
import { Detection, Image } from "../../lib/data-response";
import useWindowDimensions from "../../lib/hooks";
import { Layer, Rect, Stage, Text } from "react-konva";
import { v4 as uuidv4 } from "uuid";
import { config } from "../../util/config";
import { PhotoCamera } from "@mui/icons-material";
import Konva from "konva";

interface CameraProps {
  img: Image;
  detections: Detection[];
}

interface SaveImageButtonProps {
  callback: () => void
}

const loadImage = (src: string): Promise<HTMLImageElement> => {
  return new Promise((resolve, reject) => {
    const image = new window.Image();
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = src;
  });
};

const SaveImageButton = ({callback}: SaveImageButtonProps) => {
    return (
        <Box display="flex" justifyContent="end">
          <Tooltip title="Save Camera Image">
              <IconButton aria-label="save photo" onClick={callback}>
                  <PhotoCamera sx={{ color: "white", halign: "end"}}/>
              </IconButton>
          </Tooltip>
        </Box>
    )
}


/**
 * Displays an image and draws detection boxes around elements
 *
 * @param param0 Camera properties
 * @returns JSX.Element
 */
const Camera = ({ img, detections }: CameraProps) => {
  const ref: RefObject<HTMLImageElement> = useRef();
  const canvasRef: RefObject<Konva.Stage> = useRef();
  const { height } = useWindowDimensions();
  const [sorted, setSorted] = useState<Detection[]>(null);

  /**
   * Sort the list of detections based on detection depth to get proper on screen layering on top of the displayed image
   */
  useEffect(() => {
    if (detections) {
      setSorted(detections.slice(0).sort((a, b) => (b.depth ?? 0) - (a.depth ?? 0)));
    }
  }, [detections]);

  // To save image to disk, Kanva stage must be coverted to .png and overlaid on the original image
  const cameraButtonClicked = async () => {
     if (canvasRef.current && ref.current) {
      const canvasCopy: Konva.Stage = canvasRef.current.clone();
      const cameraCopy = ref.current.src;
      const overlayCopy = canvasCopy.toDataURL({ mimeType: "image/png" });
      const [cameraImage, overlayImage] = await Promise.all([
        loadImage(cameraCopy),
        loadImage(overlayCopy),
      ]);

      const mergedCanvas = document.createElement("canvas");
      mergedCanvas.width = overlayImage.width;
      mergedCanvas.height = overlayImage.height;

      const context = mergedCanvas.getContext("2d");
      if (!context) return;

      context.drawImage(cameraImage, 0, 0, mergedCanvas.width, mergedCanvas.height);
      context.drawImage(overlayImage, 0, 0, mergedCanvas.width, mergedCanvas.height);
      const base64 = mergedCanvas.toDataURL("image/png");

      const currentDate = new Date().toISOString();
      const link = document.createElement("a");
      link.href = base64;
      link.target = "_blank";
      link.download = `VEX_AI_${currentDate}.png`
      document.body.appendChild(link);
      link.click();
      link.parentNode?.removeChild(link);
     }
  }

  return (
    <Box>
      {img ? (
        <Box>
          <div
            style={{
              display: "flex",
              justifyContent: "center",
            }}
          >
            {/* display the image */}
            <img
              alt=""
              src={`data:image/png;base64,${img.data}`}
              height="100%"
              width="100%"
              style={{
                maxHeight: height - 50,
                maxWidth: height * 1.35,
              }}
              ref={ref}
            />
            {/* add the canvas stage for element detections on top of the image  */}
            <Stage
              height={ref.current ? ref.current["clientHeight"] : 1} // using the image dimensions
              width={ref.current ? ref.current["clientWidth"] : 1} // using the image dimensions
              style={{ position: "absolute" }}
              ref={canvasRef}
            >
              {sorted ? (
                <>
                  {sorted.map((detection) => {
                    const widthRatio =
                      img.width / (ref.current ? ref.current["clientWidth"] : 1);
                    const heightRatio =
                      img.height /
                      (ref.current ? ref.current["clientHeight"] : 1);

                    const bboxWidth = detection.screenLocation.width / widthRatio;
                    const bboxHeight =
                      detection.screenLocation.height / heightRatio;

                    const bboxX =
                      (detection.screenLocation.x *
                        (ref.current ? ref.current["clientWidth"] : 1)) /
                      config.SCALE_X;
                    const bboxY =
                      (detection.screenLocation.y *
                        (ref.current ? ref.current["clientHeight"] : 1)) /
                      config.SCALE_Y;

                    const classBoxWidth = bboxWidth;
                    const classBoxHeight = bboxHeight * 0.23;
                    const classBoxY = bboxY - classBoxHeight * 1.04;

                    if (detection.class === undefined || detection.class < 0 || detection.class >= config.elements.length) return;
                    const element = config.elements[detection.class]

                    return (
                      <>
                        {detection.depth ? ( // depth is -1 if received json detection had a depth of NaN originally
                          <Layer key={uuidv4()}>
                            {/* class box */}
                            <Rect
                              x={bboxX}
                              y={classBoxY}
                              height={classBoxHeight}
                              width={classBoxWidth}
                              fill="rgba(95, 95, 95, 0.75)"
                              stroke={config.colors.black}
                              strokeWidth={2}
                              cornerRadius={0}
                            />
                            {/* class name */}
                            <Text
                              fill={"#FFFFFF"}
                              text={`${
                                element.label
                              }`}
                              x={bboxX}
                              y={bboxY - classBoxHeight}
                              fontStyle="bold"
                              align="center"
                              verticalAlign="middle"
                              width={classBoxWidth}
                              height={classBoxHeight}
                              fontSize={classBoxHeight * 0.6}
                            />
                            {/* bounding box */}
                            <Rect
                              x={bboxX}
                              y={bboxY}
                              height={bboxHeight > 0 ? bboxHeight : 1}
                              width={bboxWidth > 0 ? bboxWidth : 1}
                              fill={
                                element.backgroundColor
                              }
                              stroke={
                                element.borderColor
                              }
                              strokeWidth={2}
                              cornerRadius={0}
                            />
                            {/* coordinates */}
                            <Text
                              fill="#FFFFFF"
                              text={`X ${detection.mapLocation.x[0]
                                .toFixed(2)
                                .toString()}m\nY ${detection.mapLocation.y[0]
                                .toFixed(2)
                                .toString()}m`}
                              align="left"
                              verticalAlign="top"
                              x={bboxX}
                              y={bboxY}
                              padding={8}
                              width={bboxWidth}
                              height={bboxHeight}
                              fontSize={bboxHeight * 0.15}
                            />
                            {/* depth */}
                            <Text
                              fill="#FFFFFF"
                              text={`Distance\n${detection.depth >= 0 ? detection.depth
                                .toFixed(2)
                                .toString()+"m" : "Unknown"}`}
                              align="right"
                              verticalAlign="bottom"
                              x={bboxX}
                              y={bboxY}
                              padding={8}
                              width={bboxWidth}
                              height={bboxHeight}
                              fontSize={bboxHeight * 0.15}
                            />
                          </Layer>
                        ) : null}
                      </>
                    );
                  })}
                </>
              ) : null}
            </Stage>
          </div>
          <div>
            <SaveImageButton callback={cameraButtonClicked}/>
          </div>
        </Box>
      ) : (
        <ConnectingToCameraProgress />
      )}
    </Box>
  );
};

export default Camera;
