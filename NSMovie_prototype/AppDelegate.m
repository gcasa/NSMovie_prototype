//
//  AppDelegate.m
//  NSMovie_prototype
//
//  Created by Gregory Casamento on 5/24/25.
//

#import <Cocoa/Cocoa.h>

#import "AppDelegate.h"
#import "FFMpegMovieView.h"

@interface AppDelegate ()
@property (strong) IBOutlet FFmpegVideoView *view;
@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction) openDocument: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSModalResponse r = [panel runModal];
    
    if (r == NSModalResponseOK)
    {
        NSString *filename = [panel filename];
        [self.view setVideoPath: filename];
#ifdef GNUSTEP
        [self.view startPlayback];
#endif
    }
}

@end
