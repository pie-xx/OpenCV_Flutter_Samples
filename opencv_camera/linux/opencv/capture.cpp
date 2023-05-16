#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
using namespace cv;

#include "capture.h"

VideoCapture vc;

void open() {
    vc.open(0);
}

void capture(char* outpath, int filno) {

    if (!vc.isOpened()) {
        return;
    }

    Mat frame;
    vc.read( frame );

    if (!frame.empty()) {
        if (filno == 1) {
            cvtColor(frame, frame, COLOR_BGR2GRAY);
            adaptiveThreshold(frame, frame, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 51, 20);
        }
        imwrite(outpath, frame);
    }
}

void close() {
    vc.release();
}