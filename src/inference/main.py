import argparse
import os
import numpy as np
import cv2
from tkinter import Tcl
from tqdm import tqdm

from yolo import YOLO
from sort import Sort as SORT
from kiou import KIOU
from util import nms_malisiewicz

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-t", "--tracker", type=str, default='sort',
                    help="chosen tracker. Choose between 'sort' and 'kiou'")
    ap.add_argument("-i", "--input", type=str, default="input/",
                    help="path to the input images folder")
    ap.add_argument("-o", "--output", type=str, default="output/out.txt",
                    help="path to the output file in MOT format")
    ap.add_argument("-r", "--representation", type=str, default="residuals",
                    help="chosen representation. Choose between 'residuals' and 'decoded'")
    args = vars(ap.parse_args())

    # Detector parameters
    if args['representation'] == "residuals":
        weights_path = "models/yolov4-residuals.weights"
        config_path = "models/yolov4-residuals.cfg"
    else:
        weights_path = "models/yolov4-decoded.weights"
        config_path = "models/yolov4-decoded.cfg"

    conf_thresh = 0.25
    nms_thresh = 0.45
    input_width = 416
    input_height = 416
    min_area_thresh = 125 # min area of the bounding boxes
    # Remove predictions < 1000 px² (scaled down to 416x416)
    ROI_path = None

    # Tracker parameters
    max_age = 50
    min_hits = 1
    iou_thresh = 0.3
    memory_fade = 1.025 # SORT only


    detector = YOLO(weights_path, config_path, conf_thresh, input_width, input_height)
    
    if args['tracker'] == "sort":
        tracker = SORT(max_age, min_hits, iou_thresh, memory_fade)
    else:
        tracker = KIOU(max_age, min_hits, iou_thresh)

    # Get sequence, the list of images
    included_extensions = ['jpg', 'jpeg', 'bmp', 'png']
    file_list = [f for f in os.listdir(args['input'])
                 if any(f.endswith(ext) for ext in included_extensions)]
    file_list_sorted = Tcl().call('lsort', '-dict', file_list)

    # counter for RGB, +1 for residues
    if args['representation'] == "residuals":
        counter = 1
    else:
        counter = 0
    output_lines = []

    if ROI_path is not None:
        with open(ROI_path, 'rb') as buffer:
            nparr = np.frombuffer(buffer.read(), dtype=np.uint8)
            roi = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    for image_name in tqdm(file_list_sorted):
        counter += 1

        # Read image
        path = os.path.join(args['input'], image_name)
        with open(path, 'rb') as buffer:
            nparr = np.frombuffer(buffer.read(), dtype=np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if ROI_path is not None:
                frame = cv2.bitwise_and(frame, roi)
            org_height, org_width, _ = frame.shape

        # Perform detection
        bboxes, classes, confidences = detector.detect(frame)

        # Convert bboxes to x1, y1, x2, y2
        for bbox in bboxes:
            bbox += np.array([0, 0, bbox[0], bbox[1]])

        if len(bboxes) != 0:
            bboxes, classes, confidences = nms_malisiewicz(bboxes, classes, confidences, nms_thresh)

        # Remove small bounding boxes
        indices = np.argwhere([(e[2] - e[0]) * (e[3] - e[1]) > min_area_thresh for e in bboxes]).flatten()
        bboxes = np.take(bboxes, indices, axis=0)
        classes = np.take(classes, indices)
        confidences = np.take(confidences, indices)

        # Perform tracking
        if args['tracker'] == 'sort':
            if len(bboxes) == 0:
                dets = np.empty((0, 6))
            else:
                dets = np.column_stack((bboxes, confidences, classes))

            res = tracker.update(dets)

            res_split = np.hsplit(res, np.array([4, 5, 6, 7]))
            bboxes = res_split[0].astype("int")
            classes = res_split[2].flatten().astype("int")
            confidences = res_split[1].flatten()
            IDs = res_split[3].flatten().astype("int")

        else:
            dets = []
            for i in range(len(bboxes)):
                bb = bboxes[i]
                det = {'bbox': bb, 'score': confidences[i], 'class': classes[i],
                    'centroid': [0.5*(bb[0] + bb[2]), 0.5*(bb[1] + bb[3])]}
                dets.append(det)
            
            res = tracker.update(dets)

            bboxes = [res[-1]['bbox'] for res in res]
            confidences = [res[-1]['score'] for res in res]
            classes = [res[-1]['class'] for res in res]
            IDs = [res[0]['id'] for res in res]

        # Convert back to x_top, y_top, width, height
        for i, bbox in enumerate(bboxes):
            bboxes[i] = np.array([bbox[0], bbox[1], bbox[2] - bbox[0], bbox[3] - bbox[1]])

        # Scale up to original width and height
        ratio_width = (org_width / input_width)
        ratio_height = (org_height / input_height)
        for i, bbox in enumerate(bboxes):
            bboxes[i] = bbox * np.array([ratio_width, ratio_height, ratio_width, ratio_height])

        # Add output to result array
        for i in range(len(bboxes)):
            bboxes[i] = bboxes[i].astype(int)
            output_lines.append("{0},{1},{2},{3},{4},{5},-1,-1,-1,-1\n".format(
                                counter, IDs[i], bboxes[i][0], bboxes[i][1], bboxes[i][2], bboxes[i][3]))
                            

    # Write result in output file
    with open(args['output'], "w") as out:
        out.writelines(output_lines)

if __name__ == "__main__":
    main()