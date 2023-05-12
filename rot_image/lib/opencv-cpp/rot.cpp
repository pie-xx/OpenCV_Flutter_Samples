#include <opencv2/opencv.hpp>
using namespace cv;
#include "rot.h"
void RotImg(char* inpath, char* outpath, int angle)
{
    Mat img = imread(inpath);
    if (img.size == 0) {
        return;
    }
    
    rotate(img, img, angle);

    imwrite(outpath, img);
}
