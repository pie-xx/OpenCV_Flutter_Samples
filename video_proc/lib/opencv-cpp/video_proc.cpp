#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/video.hpp>
using namespace cv;
#include "video_proc.h"

void getProperty(char* inpath, char* outpath, char* diffpath, int* inpara, int* outpara)
{
    // ビデオファイルを開く
    cv::VideoCapture cap(inpath);

    int pos = inpara[0];
    //if (pos < 0 || pos >= num_frames) {
     //   pos = 0;
    //}

    cap.set(cv::CAP_PROP_POS_FRAMES, pos);

    // ビデオファイルが開けなかった場合はエラーを出力して終了する
    if (!cap.isOpened()) {
        std::cout << "Error opening video file" << std::endl;
        outpara[0] = -1;
        return ;
    }

    // ビデオの幅、高さ、フレームレート、総フレーム数を取得する
    int width = cap.get(cv::CAP_PROP_FRAME_WIDTH);
    int height = cap.get(cv::CAP_PROP_FRAME_HEIGHT);
    double fps = cap.get(cv::CAP_PROP_FPS);
    int num_frames = cap.get(cv::CAP_PROP_FRAME_COUNT);
    int capformat = cap.get(cv::CAP_PROP_FORMAT);

    outpara[0] = 0;
    outpara[1] = width;
    outpara[2] = height;
    outpara[3] = num_frames;
    outpara[4] = capformat;

    // 取得したプロパティを出力する
    std::cout << "Video width: " << width << std::endl;
    std::cout << "Video height: " << height << std::endl;
    std::cout << "Video FPS: " << fps << std::endl;
    std::cout << "Number of frames: " << num_frames << std::endl;


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

    // 入力画像を膨張させる
//    cv::Mat dilated_image;
//    cv::dilate(totaldiff, dilated_image, kernel);
    try{
        if(!frame0.empty()){
            cv::imwrite(outpath, frame0);
        }
        if(!totaldiff.empty()){
            cv::imwrite(diffpath, totaldiff);
        }
    }catch(...){

    }


    // ビデオファイルを閉じる
    cap.release();

    return;
}