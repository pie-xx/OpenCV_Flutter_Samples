#include "pch.h"
#ifdef _DEBUG
#pragma comment(lib, "opencv_world460d.lib")
#else
#pragma comment(lib, "opencv_world460.lib")
#endif

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/video.hpp>
using namespace cv;
#include "video_proc.h"

void getProperty(char* inpath, char* outpath, char* diffpath, int* inpara, int* outpara)
{
    // �r�f�I�t�@�C�����J��
    cv::VideoCapture cap(inpath);

    // �r�f�I�t�@�C�����J���Ȃ������ꍇ�̓G���[���o�͂��ďI������
    if (!cap.isOpened()) {
        std::cout << "Error opening video file" << std::endl;
        outpara[0] = -1;
        return ;
    }

    // �r�f�I�̕��A�����A�t���[�����[�g�A���t���[�������擾����
    int width = cap.get(cv::CAP_PROP_FRAME_WIDTH);
    int height = cap.get(cv::CAP_PROP_FRAME_HEIGHT);
    double fps = cap.get(cv::CAP_PROP_FPS);
    int num_frames = cap.get(cv::CAP_PROP_FRAME_COUNT);

    outpara[0] = 0;
    outpara[1] = width;
    outpara[2] = height;
    outpara[3] = num_frames;

    // �擾�����v���p�e�B���o�͂���
    std::cout << "Video width: " << width << std::endl;
    std::cout << "Video height: " << height << std::endl;
    std::cout << "Video FPS: " << fps << std::endl;
    std::cout << "Number of frames: " << num_frames << std::endl;

    int pos = inpara[0];
    if (pos < 0 || pos >= num_frames) {
        pos = 0;
    }

    cap.set(cv::CAP_PROP_POS_FRAMES, pos);

    cv::Mat frame0, frame1;
    cap.read(frame0);

    Mat diff, totaldiff(frame0.size(), frame0.type(), cv::Scalar(0));

    for (int n = 0; n < inpara[1]; ++n) {
        cap.read(frame1);
        absdiff(frame0, frame1, diff);
        bitwise_or(totaldiff, diff, totaldiff);
        frame1.copyTo(frame0);
    }
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));

    // ���͉摜��c��������
    cv::Mat dilated_image;
    cv::dilate(totaldiff, dilated_image, kernel);

    cv::imwrite(outpath, frame0);
    cv::imwrite(diffpath, dilated_image);


    // �r�f�I�t�@�C�������
    cap.release();

    return;
}