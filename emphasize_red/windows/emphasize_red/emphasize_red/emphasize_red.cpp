#include "pch.h"

#ifdef _DEBUG
#pragma comment(lib, "opencv_world460d.lib")
#else
#pragma comment(lib, "opencv_world460.lib")
#endif

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
using namespace cv;
#include "emphasize_red.h"

const int smpwidth = 8;

double calc_av(Mat* img, int x, int y, int w, int h) {
    Mat limg = Mat(*img, Rect(x, y, w, h));
    return mean(limg)[0];
}

double calc_var(Mat* img, int x, int y, int w, int h, double a) {
    double t = 0;
    for (int cy = y; cy < y + h; ++cy) {
        unsigned char* src = (*img).ptr<unsigned char>(cy);
        for (int cx = x; cx < x + w; ++cx) {
            double d = double(src[cx]) - a;
            t = t + d * d;
        }
    }
    return t / (w * h);
}

void emphasize_red(char* inpath, char* outpath)
{
    Mat img = imread(inpath);
    if (img.empty()) {
        return;
    }

    Mat bwimg;
    cvtColor(img, bwimg, COLOR_BGR2GRAY);

    std::vector<std::vector<int>> vartbl(int(img.rows / smpwidth),
        std::vector<int>(int(img.cols / smpwidth)));

    // 8x8�̃u���b�N���Ƃɉ�f���̕��U�����߂�
    double t = 0;
    for (int y = 0; y < int(bwimg.rows / smpwidth); y++) {
        for (int x = 0; x < int(bwimg.cols / smpwidth); x++) {
            double a = calc_av(&bwimg, x * smpwidth, y * smpwidth,
                smpwidth, smpwidth);
            double s = calc_var(&bwimg, x * smpwidth, y * smpwidth,
                smpwidth, smpwidth, a);
            vartbl.at(y).at(x) = s;
            t = t + s;
        }
    }
    double ta = t / (int(bwimg.rows / smpwidth) * int(bwimg.cols / smpwidth));

    double ccv = 0; int cc = 0;

    for (int y = 0; y < int(img.rows / smpwidth); y++) {
        for (int x = 0; x < int(img.cols / smpwidth); x++) {
            if (vartbl.at(y).at(x) > ta / 2) {
                // ��������
                Mat pastimg = img(Rect(x * smpwidth, y * smpwidth,
                    smpwidth, smpwidth));
                // �F��(Hue)�A�ʓx(Saturation)�A���x(Value)�̐F��ԉ摜�����߂�
                Mat hsvimg;
                cvtColor(pastimg, hsvimg, COLOR_BGR2HSV);
                std::vector<Mat> planes;
                split(hsvimg, planes);
                // �ʓx(Saturation)�̕��ς����߂�
                ccv = ccv + mean(planes[1])[0];
                cc++;
            }
        }
    }

    double cca = ccv / cc;
    Mat kernel = getStructuringElement(MORPH_RECT, Size(4, 4));
    for (int y = 0; y < int(img.rows / smpwidth); y++) {
        for (int x = 0; x < int(img.cols / smpwidth); x++) {
            if (vartbl.at(y).at(x) > ta / 2) {
                // ��������
                Mat pastimg = img(Rect(x * smpwidth, y * smpwidth,
                    smpwidth, smpwidth));
                // �F��(Hue)�A�ʓx(Saturation)�A���x(Value)�̐F��ԉ摜�����߂�
                Mat hsvimg;
                cvtColor(pastimg, hsvimg, COLOR_BGR2HSV);
                std::vector<Mat> planes;
                split(hsvimg, planes);

                // �ʓx�����ς�肿����Ƒ傫���Ƃ��A�ԕ����Ɣ���
                if (cca * 1.1 < mean(planes[1])[0]) {
                    std::vector<Mat> rgbplanes;
                    split(pastimg, rgbplanes);
                    // BGR���ꂼ��c��܂��č�������
                    for (int n = 0; n < 3; ++n) {
                        Mat rimg = rgbplanes[n];
                        bitwise_not(rimg, rimg);
                        dilate(rimg, rimg, kernel);
                        bitwise_not(rimg, rimg);
                    }
                    merge(rgbplanes, pastimg);
                }
            }
        }
    }

    imwrite(outpath, img);
}
