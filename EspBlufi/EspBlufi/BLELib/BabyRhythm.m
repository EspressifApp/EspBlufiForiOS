

#import "BabyRhythm.h"

@implementation BabyRhythm {
    BOOL isOver;
    BBBeatsBreakBlock blockOnBeatBreak;
    BBBeatsOverBlock blockOnBeatOver;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //beatsInterval
        _beatsInterval = beatsDefaultInterval;
    }
    return  self;
}

- (void)beats {
    
    if (isOver) {
        //Log(@">>>beats isOver");
        return;
    }
    
    //Log(@">>>beats at :%@",[NSDate date]);
    if (self.beatsTimer) {
        [self.beatsTimer setFireDate: [[NSDate date]dateByAddingTimeInterval:self.beatsInterval]];
    }
    else {
       self.beatsTimer = [NSTimer timerWithTimeInterval:self.beatsInterval target:self selector:@selector(beatsBreak) userInfo:nil repeats:YES];
        [self.beatsTimer setFireDate: [[NSDate date]dateByAddingTimeInterval:self.beatsInterval]];
        [[NSRunLoop currentRunLoop] addTimer:self.beatsTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)beatsBreak {
     //Log(@">>>beatsBreak :%@",[NSDate date]);
    [self.beatsTimer setFireDate:[NSDate distantFuture]];
    if (blockOnBeatBreak) {
        blockOnBeatBreak(self);
    }
}

- (void)beatsOver {
    //Log(@">>>beatsOver :%@",[NSDate date]);
    [self.beatsTimer setFireDate:[NSDate distantFuture]];
    isOver = YES;
    if (blockOnBeatOver) {
        blockOnBeatOver(self);
    }
    
}

- (void)beatsRestart {
    //Log(@">>>beatsRestart :%@",[NSDate date]);
    isOver = NO;
    [self beats];
}

- (void)setBlockOnBeatsBreak:(void(^)(BabyRhythm *bry))block {
    blockOnBeatBreak = block;
}

- (void)setBlockOnBeatsOver:(void(^)(BabyRhythm *bry))block {
    blockOnBeatOver = block;
}

@end
