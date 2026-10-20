import React from "react";
import { Layer, Image as KonvaImage } from "react-konva";
import { config } from "../../util/config";
import { useAppSelector } from "../../state/hooks";
import { Element, ElementType } from "../../lib/types";
import { v4 as uuidv4 } from "uuid";
import useImage from "use-image";

interface DetectionLayerProps {
  fieldWidth: number;
  fieldHeight: number;
}

/**
 * Displays elements on the field detected by the robot
 *
 * @param param0 Detection layer properties
 * @returns JSX.Element
 */
const DetectionLayer = ({ fieldWidth, fieldHeight }: DetectionLayerProps) => {
  const detections = useAppSelector((state) => state.data.response.detections);
  const position = useAppSelector((state) => state.data.response.position);
  const scale = useAppSelector((state) => state.app.scale);

  // Konva draws siblings in array order and react-konva re-asserts JSX order on
  // every render, so the zIndex prop is ignored — control draw order by sorting
  // the detections by element.zIndex here (lower drawn first, higher on top).
  const ordered = detections
    ? [...detections].sort(
        (a, b) =>
          (config.elements[a.class ?? -1]?.zIndex ?? 0) -
          (config.elements[b.class ?? -1]?.zIndex ?? 0)
      )
    : [];
    

  return (
    <Layer>
      {detections ? (
        <>
          {ordered.map((detection) => {
            if (detection.class === undefined || detection.class < 0 || detection.class >= config.elements.length) return;
            const element = config.elements[detection.class]
            if (!element.size || !element.texture) return;

            const image = new Image();
            let rotation = 0;

            if (typeof(element.texture) === "string") {
              image.src = element.texture
            } else if ((detection.screenLocation?.width ?? 0) > (detection.screenLocation?.height ?? 0)) {
              image.src = element.texture.horizontal;
              rotation = position?.azimuth ?? 0;
            } else {
              image.src = element.texture.vertical;
            }

            const widthScale = scale * element.size.width * element.size.scale;
            const heightScale = scale * element.size.height * element.size.scale;

            return (
              <>
                {detection.depth !== -1 ? (
                  <KonvaImage
                    key={`${
                      element.label
                    }-${uuidv4()}`}
                    alt=""
                    image={image}
                    x={(detection.mapLocation?.x?.[0] ?? 0) * scale}
                    y={(detection.mapLocation?.y?.[0] ?? 0) * scale * -1}
                    width={widthScale}
                    height={heightScale}
                    offsetX={widthScale / 2}
                    offsetY={heightScale / 2}
                    rotation={rotation}
                  />
                ) : null}
              </>
            );
          })}
        </>
      ) : null}
    </Layer>
  );
};

export default DetectionLayer;
