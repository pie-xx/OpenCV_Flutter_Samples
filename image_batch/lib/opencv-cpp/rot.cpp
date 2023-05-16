#include <opencv2/opencv.hpp>
using namespace cv;
#include "rot.h"
void RotImg(char* inpath, char* outpath, int angle)
{
    try {
        Mat img = imread(inpath);
        if (img.empty()) {
            return;
        }
        rotate(img, img, angle);
        imwrite(outpath, img);
    }
    catch(...) {
        return;
    }
}
