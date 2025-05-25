//
//  FFMpegMovieView.h
//  NSMovie_prototype
//
//  Created by Gregory Casamento on 5/24/25.
//

// ffmpeg_nsview_player.m

#import <Cocoa/Cocoa.h>

#ifdef GNUSTEP
// FFmpeg headers
// extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
// }
#endif

@interface FFmpegVideoView : NSView {
    NSImage *currentFrame;
    dispatch_queue_t decodeQueue;
#ifdef GNUSTEP
    AVFormatContext *formatContext;
    AVCodecContext *codecContext;
    AVFrame *frame;
    AVFrame *frameRGB;
    struct SwsContext *swsCtx;
    int videoStreamIndex;
    uint8_t *buffer;
#endif
    NSString *videoPath;
    BOOL running;
    NSThread *decodeThread;
}

- (instancetype) initWithFrame: (NSRect)frameRect; // videoPath:(NSString *)path;
- (void) stopPlayback;
- (void) startPlayback;
- (void) setVideoPath: (NSString *)path;

@end
