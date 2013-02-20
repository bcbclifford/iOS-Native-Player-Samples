//
//  AppleControls.m
//  AppleLookAlike
//
//  Created by Tom Abbott on 2/12/13.
//  Copyright (c) 2013 Brightcove. All rights reserved.
//

#import "AppleControls.h"
#import "BCEvent.h"
#import "BCEventEmitter.h"
#import "BCRegisteringEventEmitter.h"
#import "VideoUtils.h"

@implementation AppleControls

#pragma mark control actions

- (IBAction)handleTap:(UITapGestureRecognizer*) recognizer
{
    [self handleTimer];
    
    CGPoint location_bottom = [recognizer locationInView:self.bottomToolbar];
    UIView *hit_bottom =[self.bottomToolbar hitTest:location_bottom withEvent:nil];
    CGPoint location_top = [recognizer locationInView:self.topToolbar];
    UIView *hit_top =[self.topToolbar hitTest:location_top withEvent:nil];
    
    if (hit_bottom || hit_top) {
        return;
    }
    
    if(self.controlsView.alpha == 0.0){
        [self.emitter emit:BCEventShowControls];
    }
    else
    {
        [self.emitter emit:BCEventHideControls];
    }
}

- (IBAction)playPauseButtonPressed:(id)sender
{
    if(self.isPaused)
    {
        [self.emitter emit:BCEventPlay];
        self.isPaused = NO;
    }
    else
    {
        [self.emitter emit:BCEventPause];
        self.isPaused = YES;
    }
}

// ???: How do we know that we can advance the queue?
- (IBAction)skipForwardButtonPressed:(id)sender
{
    [self.emitter emit:BCEventAdvanceQueue];
}

- (IBAction)skipBackwardsButtonPressed:(id)sender
{
    NSValue *zero_time =  [NSValue valueWithCMTime:kCMTimeZero];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: zero_time, @"time", zero_time, @"toleranceBefore", zero_time, @"toleranceAfter", nil];
    [self.emitter emit:BCEventSeekTo withDetails:dict];
}

// TODO: Implement correct action for the done button
- (IBAction)doneButtonPressed:(id)sender
{
    
}

// TODO: Implement correct action for the resize button
- (IBAction)resizeButtonPressed:(id)sender
{
    
}

/**
 *  When the slider value changes incrementally update control time values
 */
-(void)sliderValueChanged:(UISlider *)sender
{
    NSTimeInterval timePlayed_seconds = sender.value * CMTimeGetSeconds(self.duration);
    
    NSTimeInterval timeLeft_seconds = CMTimeGetSeconds(self.duration) - timePlayed_seconds;
    
    self.timePlayed.text = [VideoUtils makeTimeReadable:timePlayed_seconds];
    self.timeLeft.text = [@"-" stringByAppendingString:[VideoUtils makeTimeReadable:timeLeft_seconds]];
    
}

/**
 * When user touched down on the slider, emit that slider has begin
 */
-(void)sliderTouchDown:(UISlider *)sender
{
    [self.emitter emit:BCEventSliderBegin];
}
/**
 * When slider is touched up emit that the slider has ended with the sender
 */
-(void)sliderTouchUp:(UISlider *)sender
{
    [self.emitter emit:BCEventSliderEnd withDetails:[NSDictionary dictionaryWithObjectsAndKeys:sender, @"sender", nil]];
}

/**
 * Utility method to handle reseting the timer for animations for hiding the controls
 */
-(void)handleTimer
{
    if(self.timer.isValid)
    {
        [self.timer invalidate];
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    
}

/**
 * When controls are hidden, emit the hide controls event
 */
-(void)hideControls
{
    if(self.controlsView.alpha != 0.0){
        
        [self.emitter emit:BCEventHideControls];
    }
}

#pragma mark Initialization

- (id)initWithEventEmitter:(BCEventEmitter *)eventEmitter view:(UIView *)view
{
    if(self = [super initWithEventEmitter:eventEmitter])
    {
        [self initializeControlView:view];
    }
    
    return self;
}

/**
 *
 */
- (void) initializeControlView:(UIView *)view
{
    //Load iOSLookALikeMovieControls
    [[NSBundle mainBundle] loadNibNamed:@"iOSLookAlikeMovieControls" owner:self options:nil];
    
    //Position and center
    self.mainView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.controlsView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin);
    
    //Init components
    self.timePlayed = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 44, 20)];
    [self applyTextStyles:self.timePlayed];
    
    self.timeLeft = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 44, 20)];
    [self applyTextStyles:self.timeLeft];
    
    self.scrubber = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 530, 20)];
    self.scrubber.maximumTrackTintColor = [UIColor clearColor];
    self.scrubber.minimumTrackTintColor = [UIColor lightGrayColor];
    [self.scrubber setThumbImage:[UIImage imageNamed:@"handle.png"] forState:UIControlStateNormal];
    
    self.scrubber.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //Gestures
    [self.scrubber addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.scrubber addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.scrubber addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    
    //Toolbar Items
    NSMutableArray *items = [[self.topToolbar items] mutableCopy];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
    [items addObject:[[UIBarButtonItem alloc] initWithCustomView:self.timePlayed]];
    [items addObject:[[UIBarButtonItem alloc] initWithCustomView:self.scrubber]];
    [items addObject:[[UIBarButtonItem alloc] initWithCustomView:self.timeLeft]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(editAction)]];
    
    [self.topToolbar setItems:items animated:NO];
    
    //Bottom Toolbar
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"handle.png"] forState:UIControlStateNormal];
    self.controlsView.clipsToBounds = YES;
    CALayer *layer = [self.controlsView layer];
    [layer setCornerRadius:8.0f];
    [layer setBorderColor:[UIColor darkGrayColor].CGColor];
    [layer setBorderWidth:1.0f];
    
    //Add View
    [view addSubview:self.mainView];
}

//Utility methods to set styles of labels in toolbar
- (void) applyTextStyles:(UILabel *)label
{
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = @"00:00";
    label.textColor = [UIColor whiteColor];
}

#pragma mark BCComponent methods

+(NSArray *)allowedEmits
{
    return [NSArray arrayWithObjects:BCEventPause, BCEventPlay, BCEventShowControls, BCEventHideControls, BCEventSliderBegin, BCEventSliderEnd, BCEventSeekTo, BCEventAdvanceQueue, nil];
}

+(NSArray *)allowedListeners
{
    return [NSArray arrayWithObjects:BCEventReadyToPlay, BCEventVideoDidEnd, BCEventVideoDidPlay, BCEventPaused, BCEventVideoProgress, BCEventVideoDurationChanged, BCEventSliderBegin, BCEventSliderEnd, BCEventVideoDurationChanged, BCEventHideControls, BCEventShowControls, nil];
}

-(void)setupEventListeners
{
    AppleControls * __weak weakself = self;
    
    //When duration changes, update the label
    [self.emitter on:BCEventVideoDurationChanged callBlock:^(BCEvent *event) {
        AVPlayerItem *item = [event.details objectForKey:@"playerItem"];
        
        if(item.duration.timescale){
            weakself.duration = item.duration;
        }
    }];
    
    //This isn't correct... keep it here for now...
    [self.emitter on:BCEventReadyToPlay callBlock:^(BCEvent *event) {
        [weakself.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]];
    }];
    
    //Handle when the video did play by changing to pause and starting timer on progress once
    [self.emitter on:BCEventVideoDidPlay callBlock:^(BCEvent *event) {
        [weakself.playPauseButton setImage:[UIImage imageNamed:@"pause.png"]];
        
        [self.emitter once:BCEventVideoProgress callBlock:^(BCEvent *event) {
            [weakself handleTimer];
        }];
    }];
    
    //Handle pause by changing the pause button to play when paused
    [self.emitter on:BCEventPaused callBlock:^(BCEvent *event) {
        [weakself.playPauseButton setImage:[UIImage imageNamed:@"play.png"]];
    }];
    
    //Handle hiding controls by fading out
    [self.emitter on:BCEventHideControls callBlock:^(BCEvent *event) {
        [UIView animateWithDuration:0.3 animations:^{
            weakself.topToolbar.alpha = 0.0;
            weakself.controlsView.alpha = 0.0;
        }];
    }];
    
    //Handle showing controls by fading in
    [self.emitter on:BCEventShowControls callBlock:^(BCEvent *event) {
        [UIView animateWithDuration:0.3 animations:^{
            weakself.topToolbar.alpha = 1.0;
            weakself.controlsView.alpha = 1.0;
        }];
    }];
    
    //Handle when user starts scrubbing, make sure to invalidate timer
    [self.emitter on:BCEventSliderBegin callBlock:^(BCEvent *event) {
        weakself.isScrubbing = YES;
        [self.timer invalidate];
    }];
    
    //Handle the seek to when the slider is released
    [self.emitter on:BCEventSliderEnd callBlock:^(BCEvent *event) {
        weakself.isScrubbing = NO;
        
        //Calculate the time and tolerance to move to
        UISlider *slider = (UISlider *)[event.details objectForKey:@"sender"];
        double seconds = CMTimeGetSeconds(weakself.duration) * slider.value;
        CMTime time = CMTimeMake(seconds * 600.0, 600.0);
    
        NSValue *tolerance = [NSValue valueWithCMTime:kCMTimeZero];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCMTime:time], @"time", tolerance, @"toleranceBefore", tolerance, @"toleranceAfter", nil];
        
        //Emit SeekTo, then after seeking, start timer again for hiding controls
        [weakself.emitter emit:BCEventSeekTo withDetails:dict thenCallBlock:^(BCEvent *event) {
            [weakself handleTimer];
        }];
        
    }];
    
    //When the video progresses, update the time played and progress bar
    [self.emitter on:BCEventVideoProgress callBlock:^(BCEvent *event) {
        
        //Don't update if user is scrubbing
        if(!weakself.isScrubbing){
            
            AVPlayerItem *item = [event.details objectForKey:@"playerItem"];
            NSTimeInterval time = CMTimeGetSeconds(item.currentTime);
            NSTimeInterval timeLeft = CMTimeGetSeconds(weakself.duration) - time;
            
            //Time label
            weakself.timePlayed.text = [VideoUtils makeTimeReadable:time];
            weakself.timeLeft.text = [@"-" stringByAppendingString:[VideoUtils makeTimeReadable:timeLeft]];
            
            //Progress bar
            weakself.scrubber.value = time / CMTimeGetSeconds(item.duration);
            
            // TODO:  Implement buffer logic
            /*
            NSArray *loadedTimeRanges = [item loadedTimeRanges];
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval result = startSeconds + durationSeconds;
            */
        }
    }];

}


@end
