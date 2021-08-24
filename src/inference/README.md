# ResidualsTracking: Python Inference

This readme will guide you to obtain the tracking results (in MOT format) using one of the combination: YOLOv4 + SORT, Tiny-YOLOv4 + SORT, YOLOv4 + KIOU or Tiny-YOLOv4 + KIOU.

## Installation

1. Clone this repository
   ```
   git clone https://github.com/JonathanSamelson/ResidualsTracking.git
   cd ResidualsTracking
   ```

2. Create a new Anaconda environment (Recommended)
   ```
   conda create --name ResidualsTracking python=3.7
   ```

3. Install the depencies
    ```
    pip install -r requirements.txt
    ```

4. Create input and output folders
    ```
    mkdir input
    mkdir output
    ```

Optional: If you wish to use GPUs for detection inference, you need to build OpenCV manually, please refer to  https://pypi.org/project/opencv-python/

## Run the code

Check the path to your Python interpreter and then run the following command:
```
E:/Anaconda3/envs/ResidualsTrackings/python.exe src/inference/main.py
```

| Option | | Description | Default
| -----------| ------ | ----------- | ----------- |
| -d |--detector | Chosen detector. Either 'yolo' or 'tiny-yolo' | 'yolo'
| -t |--tracker | Chosen tracker. Either 'sort' or 'kiou' | 'sort'
| -r |--representation | Chosen representation. Either 'residual' or 'decoded' | 'residual'
| -i |--input | Path to input folder containing images (.png/.jpg/.bmp) in lexical order| 'input'
| -o |--output | Path to the output file | output/out.txt

The parameters used to generate the results of our paper are set by default. You will find them at the top of `main.py`. Paths to YOLO weights and config files can also be modified.

| Parameter | Description | Default
| -----------| ------------ | -------- |
| conf_thresh | Minimum score for a prediction to be kept | 0.25
| nms_thresh | Threshold for the non-max-suppression | 0.45
| input_width | Input image width of the YOLO model | 416
| input_height | Input image weight of the YOLO model | 416
| min_area_thresh | Minimum area of the bounding boxes* | 125
| ROI_path | Path to the mask defining the region of interest |None
| max_age | Maximum frames a track remains pending before termination | 50
| min_hits | Minimum track length in frames before a track is created | 1
| iou_thresh | Minimum IOU threshold to associate two bounding boxes | 0.3
| memory_fade | >1 turns on the fading memory filter | 1.025


\* This is related to the input width and height of the image (416x416 by default)


## Evaluate the results

We recommend to use HOTA to evaluate the tracking results. Code for evaluation can be found at https://github.com/JonathonLuiten/TrackEval. See [this readme](https://github.com/JonathonLuiten/TrackEval/blob/master/docs/MOTChallenge-Official/Readme.md) more specifically for data in MOT format.