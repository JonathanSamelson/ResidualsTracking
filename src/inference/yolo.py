import cv2
import numpy as np


class YOLO:

    def __init__(self, weights_path, config_path, conf_thresh, input_width=416, input_height=416):
        """Initiliazes the YOLO detector with the given parameters.

        Args:
            weights_path ([type]): Path to the weights of the YOLO model
            config_path ([type]): Path to YOLO
            conf_thresh ([type]): Minimum confidence threshold of the predictions
            input_width ([type]): Input width of the model (multiple of 32). Default is 416.
            input_height ([type]): Input height of the model (multiple of 32). Default is 416.
        """

        self.input_width = input_width
        self.input_height = input_height
        self.conf_thresh = conf_thresh
        self.nms_across_classes = True

        # To use the GPU, you may need to build opencv manually
        # to enable modules such as CUDA. See https://pypi.org/project/opencv-python/
        self.ocv_gpu = False
        self.ocv_half_precision = False # On supported GPUs only

        self.weights_path = weights_path
        self.config_path = config_path

        self.net = cv2.dnn_DetectionModel(self.weights_path, self.config_path)
        self.net.setInputSize(self.input_width, self.input_height)
        self.net.setInputScale(1.0 / 255)
        self.net.setInputSwapRB(True)
        self.net.setNmsAcrossClasses(self.nms_across_classes)


        if self.ocv_gpu:
            self.net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
            if self.ocv_half_precision:
                self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA_FP16)
            else:
                self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)
        else:
            self.net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
            self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)


    def detect(self, org_frame):
        """Perfom the inference on the given image

        Args:
            org_frame ([np.ndarray]): The frame to infer YOLO detections

        Returns:
            np.array: bounding boxes ([[x_top, y_top, width, height], ...])
            np.array: classes (flat array)
            np.array: confidences (flat array)
        """
        if org_frame.shape[:2] != (self.input_height, self.input_width):
            frame = cv2.resize(org_frame, (self.input_width, self.input_height), interpolation=cv2.INTER_AREA)

        classes, confidences, boxes = self.net.detect(frame, confThreshold=self.conf_thresh, nmsThreshold=0)

        if len(classes) > 0:
            classes = classes.flatten()
            confidences = confidences.flatten()

        return np.array(boxes), np.array(classes), np.array(confidences)