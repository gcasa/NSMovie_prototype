//
//  FFmpegVideoView.m
//  NSMovie_prototype
//
//  Created by Gregory Casamento on 5/24/25.
//

#import "FFMpegMovieView.h"

// ffmpeg_nsview_player.m

@implementation FFmpegVideoView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    return self;
}

- (void)dealloc {
    [self stopPlayback];
    // [super dealloc];
}

- (void)setVideoPath:(NSString *)path {
    videoPath = [path copy];
    [self prepareDecoder];
}

- (void)prepareDecoder {
#ifdef GNUSTEP
    formatContext = avformat_alloc_context();
    if (avformat_open_input(&formatContext, [videoPath UTF8String], NULL, NULL) != 0) return;
    if (avformat_find_stream_info(formatContext, NULL) < 0) return;

    videoStreamIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIndex = i;
            break;
        }
    }
    if (videoStreamIndex == -1) return;

    AVCodecParameters *codecPar = formatContext->streams[videoStreamIndex]->codecpar;
    AVCodec *codec = avcodec_find_decoder(codecPar->codec_id);
    codecContext = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codecContext, codecPar);
    if (avcodec_open2(codecContext, codec, NULL) < 0) return;

    frame = av_frame_alloc();
    frameRGB = av_frame_alloc();

    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, codecContext->width, codecContext->height, 1);
    buffer = (uint8_t *)av_malloc(numBytes * sizeof(uint8_t));
    av_image_fill_arrays(frameRGB->data, frameRGB->linesize, buffer, AV_PIX_FMT_RGB24,
                         codecContext->width, codecContext->height, 1);

    swsCtx = sws_getContext(codecContext->width, codecContext->height, codecContext->pix_fmt,
                            codecContext->width, codecContext->height, AV_PIX_FMT_RGB24,
                            SWS_BILINEAR, NULL, NULL, NULL);
#endif
}

- (void)startPlayback {
#ifdef GNUSTEP
    running = YES;
    decodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(startDecoding) object:nil];
    [decodeThread start];
#endif
}

- (void)startDecoding {
    while (running) {
        [self decodeAndDisplayNextFrame];
        [NSThread sleepForTimeInterval:1.0 / 30.0];
    }
}

- (void)stopPlayback {
#ifdef GNUSTEP
    running = NO;
    if (decodeThread) {
        [decodeThread cancel];
        decodeThread = nil;
    }
    if (frame) av_frame_free(&frame);
    if (frameRGB) av_frame_free(&frameRGB);
    if (buffer) av_free(buffer);
    if (codecContext) avcodec_free_context(&codecContext);
    if (formatContext) avformat_close_input(&formatContext);
    if (swsCtx) sws_freeContext(swsCtx);
#endif
}

- (void)decodeAndDisplayNextFrame {
#ifdef GNUSTEP
    AVPacket packet;
    av_init_packet(&packet);
    packet.data = NULL;
    packet.size = 0;

    while (av_read_frame(formatContext, &packet) >= 0) {
        if (!running) break;
        if (packet.stream_index == videoStreamIndex) {
            avcodec_send_packet(codecContext, &packet);
            if (avcodec_receive_frame(codecContext, frame) == 0) {
                sws_scale(swsCtx, (const uint8_t * const *)frame->data, frame->linesize, 0,
                          codecContext->height, frameRGB->data, frameRGB->linesize);

                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                    initWithBitmapDataPlanes:frameRGB->data
                                  pixelsWide:codecContext->width
                                  pixelsHigh:codecContext->height
                               bitsPerSample:8
                             samplesPerPixel:3
                                    hasAlpha:NO
                                    isPlanar:NO
                              colorSpaceName:NSCalibratedRGBColorSpace
                                 bytesPerRow:frameRGB->linesize[0]
                                bitsPerPixel:24];

                NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(codecContext->width, codecContext->height)];
                [image addRepresentation:rep];

                [self performSelectorOnMainThread:@selector(updateImage:) withObject:image waitUntilDone:NO];
                break;
            }
        }
        av_packet_unref(&packet);
    }
#endif
}

- (void)updateImage:(NSImage *)image {
    currentFrame = image;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (currentFrame) {
        [currentFrame drawInRect:self.bounds];
    }
}

@end
