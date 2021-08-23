import numpy as np


def nms_malisiewicz(bboxes, classes, confidences, nms_thresh):
    """This code comes from [1] and was adapted to include confidence score.
        It was originally designed by Dr Tomasz Malisiewicz.

    .. [1] http://www.pyimagesearch.com/2015/02/16/
        faster-non-maximum-suppression-python/

    Args:
        bboxes (array of array of ints): the bounding boxes coords
        classes (array of ints): the classes of the detected objects
        confidences (array of floats): the confidence score in the prediction
        nms_thresh (float): threshold to apply the non-maximum suppression
    """
    boxes = bboxes.astype(float)
    pick = []

    x1, y1, x2, y2 = boxes[:, 0], boxes[:, 1], boxes[:, 2], boxes[:, 3]

    area = (x2 - x1 + 1) * (y2 - y1 + 1)
    if confidences is not None:
        idxs = np.argsort(confidences)
    else:
        idxs = np.argsort(y2)

    while len(idxs) > 0:
        last = len(idxs) - 1
        i = idxs[last]
        pick.append(i)

        xx1 = np.maximum(x1[i], x1[idxs[:last]])
        yy1 = np.maximum(y1[i], y1[idxs[:last]])
        xx2 = np.minimum(x2[i], x2[idxs[:last]])
        yy2 = np.minimum(y2[i], y2[idxs[:last]])

        w = np.maximum(0, xx2 - xx1 + 1)
        h = np.maximum(0, yy2 - yy1 + 1)

        overlap = (w * h) / area[idxs[:last]]

        idxs = np.delete(idxs, np.concatenate(([last], np.where(overlap > nms_thresh)[0])))

    bboxes = np.take(bboxes, pick, axis=0)
    classes = np.take(classes, pick)
    confidences = np.take(confidences, pick)
    return bboxes, classes, confidences