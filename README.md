# ResidualsTracking
This repository hosts code and models of the paper [Deep Learning-Based Object Tracking via Compressed Domain Residual Frames](http://journal.frontiersin.org/article/10.3389/frsip.2021.765006) by Karim El Khoury, Jonathan Samelson and Benoît Macq.

## Description

Our goal in using residual frames to perform object tracking is to address three major needs in video surveillance: 
1. The need for video compression
2. The need for video analysis
3. The need for privacy protection

For this purpose, the residual frame is a light representation that comes from the compressed domain at no additional cost. Our results show that using this representation can be just as effective as using classical decoded frames while reducing the amount of information leakage in a video stream.

For instance, residual frames can be used to detect only objects of interest or to reduce the number of false positives as they only feature moving objects.


## Structure

It is structured as follows:
- `/src/ABMA/` contains the Matlab code of the Adaptive Block Matching Algorithm (ABMA) allows to generate the residual frame of a video sequence. See [ABMA Readme](https://github.com/JonathanSamelson/ResidualsTracking/tree/main/src/ABMA/README.md) for specific instructions.
- `/src/inference` contains the Python code to obtain the tracking results (in MOT format) using decoded frames (classical representation) or the residual frames (representation from the compressed domain). See [Inference Readme](https://github.com/JonathanSamelson/ResidualsTracking/tree/main/src/inference/README.md) for specific instructions.
- `/models/` contains the YOLOv4 and Tiny-YOLOv4 weights and config files used to get the detections. Those models are trained to detect vehicles.

Once the results are obtained, HOTA metric can be used to evaluate the performance of the tracking. See [TrackEval](https://github.com/JonathonLuiten/TrackEval/blob/master/docs/MOTChallenge-Official/) for the instructions.

## References

Refer to the following repositories for more information on individual algorithms. Part of the code present in this repository was adapted from those repositories, see individual source files for details.

YOLO & Tiny-YOLO training: https://github.com/AlexeyAB/darknet

YOLO & Tiny-YOLO inference: [OpenCV Documentation - DNN module](https://docs.opencv.org/4.5.3/d0/db7/tutorial_js_table_of_contents_dnn.html)

SORT: https://github.com/abewley/sort

KIOU: https://github.com/siyuanc2/kiout 

Block Matching Algorithm for Motion Estimation: [Block Matching Algorithms for Motion Estimation](https://nl.mathworks.com/matlabcentral/fileexchange/8761-block-matching-algorithms-for-motion-estimation)


This repository is released under GPL-3.0 License, please consult LICENSE file for details.
