//
//  STLoopProgressView.m
//  STLoopProgressView
//
//  Copyright 2017-2018 Espressif Systems (Shanghai) PTE LTD.
//  This code is licensed under Espressif MIT License, found in LICENSE file.
//

#import "STLoopProgressView.h"
#import "STLoopProgressView+BaseConfiguration.h"
#import "UIColor+Hex.h"

#define SELF_WIDTH CGRectGetWidth(self.bounds)
#define SELF_HEIGHT CGRectGetHeight(self.bounds)


#define CompassToCartesian(rad) ((rad) - M_PI / 2 )
#define DEGREE_TO_RADIAN(degree) (((degree) * M_PI) / 180.0f)

@interface STLoopProgressView ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) CAShapeLayer *colorMaskLayer; // 渐变色遮罩
@property (strong, nonatomic) CAShapeLayer *colorLayer; // 渐变色
@property (strong, nonatomic) CAShapeLayer *blueMaskLayer; // 蓝色背景遮罩

@property(strong,nonatomic) CAGradientLayer *leftlayer;
@property(strong,nonatomic) CAGradientLayer *rightlayer;

@property (strong, nonatomic) CALayer *outerCircleLayer;

@end

@implementation STLoopProgressView

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.backgroundColor = [STLoopProgressView backgroundColor];
    
    [self setupColorLayer];
    [self setupColorMaskLayer];
    [self setupBlueMaskLayer];
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [STLoopProgressView backgroundColor];
        
        [self setupColorLayer];
        [self setupColorMaskLayer];
        [self setupBlueMaskLayer];
        [self drawHandle];
        [self setupGestureRecognizer];
        
    }
    return self;
}

//白色圆点
- (void)drawHandle {
    CGPoint handleCenter = [self pointOnCircleAtRadian:DEGREE_TO_RADIAN(100)];
    float LS_HANDLE_RADIUS=[STLoopProgressView lineWidth]/2;
    _outerCircleLayer = [CALayer layer];
    _outerCircleLayer.bounds = CGRectMake(0, 0, LS_HANDLE_RADIUS * 2, LS_HANDLE_RADIUS * 2);
    _outerCircleLayer.cornerRadius = LS_HANDLE_RADIUS;
    _outerCircleLayer.position = handleCenter;
    _outerCircleLayer.shadowColor = [UIColor lightGrayColor].CGColor;
    _outerCircleLayer.shadowOffset = CGSizeZero;
    _outerCircleLayer.shadowOpacity = 0.7;
    _outerCircleLayer.shadowRadius = 3;
    _outerCircleLayer.borderWidth = 1;
    _outerCircleLayer.borderColor = [UIColor lightGrayColor].CGColor;
    _outerCircleLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:_outerCircleLayer];
    
}

- (CGPoint)pointOnCircleAtRadian:(CGFloat)radian {
    CGPoint centerPoint=CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat radius=self.bounds.size.width/2.2;
    CGFloat cartesianRadian = CompassToCartesian(radian);
    CGVector offset = CGVectorMake(radius * cos(cartesianRadian), radius * sin(cartesianRadian));
    return CGPointMake(centerPoint.x + offset.dx, centerPoint.y + offset.dy);
}

/**
 *  设置整个蓝色view的遮罩
 */
- (void)setupBlueMaskLayer {
    
    CAShapeLayer *layer = [self generateMaskLayer];
    self.layer.mask = layer;
    self.blueMaskLayer = layer;
}

/**
 *  设置渐变色，渐变色由左右两个部分组成，左边部分由黄到绿，右边部分由黄到红
 */
- (void)setupColorLayer {
    
    self.colorLayer = [CAShapeLayer layer];
    self.colorLayer.frame = self.bounds;
    [self.layer addSublayer:self.colorLayer];

    CAGradientLayer *leftLayer = [CAGradientLayer layer];
    leftLayer.frame = CGRectMake(0, 0, SELF_WIDTH / 2, SELF_HEIGHT);
    // 分段设置渐变色
    //leftLayer.locations = @[@0.05,@0.5, @0.7,@0.9];
    
    [self.colorLayer addSublayer:leftLayer];
    
    CAGradientLayer *rightLayer = [CAGradientLayer layer];
    rightLayer.frame = CGRectMake(SELF_WIDTH / 2, 0, SELF_WIDTH / 2, SELF_HEIGHT);
    //rightLayer.locations = @[@0.3, @0.9, @1];
    
    [self.colorLayer addSublayer:rightLayer];
    self.rightlayer=rightLayer;
    self.leftlayer=leftLayer;
    
    
//    leftLayer.colors = @[(id)[UIColor colorWithHexString:@"#7aC4Eb"].CGColor,(id)[UIColor colorWithHexString:@"#7aC4Eb"].CGColor];
//        
//    rightLayer.colors = @[(id)[UIColor colorWithHexString:@"#7aC4Eb"].CGColor, (id)[UIColor colorWithHexString:@"#7aC4Eb"].CGColor];
    leftLayer.colors = @[(id)[UIColor whiteColor].CGColor,(id)[UIColor whiteColor].CGColor];
    
    rightLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor];
    
}

/**
 *  设置渐变色的遮罩
 */
- (void)setupColorMaskLayer {
    
    CAShapeLayer *layer = [self generateMaskLayer];
    layer.lineWidth = [STLoopProgressView lineWidth] + 0.5; // 渐变遮罩线宽较大，防止蓝色遮罩有边露出来
    self.colorLayer.mask = layer;
    self.colorMaskLayer = layer;
}

/**
 *  生成一个圆环形的遮罩层
 *  因为蓝色遮罩与渐变遮罩的配置都相同，所以封装出来
 *
 *  @return 环形遮罩
 */
- (CAShapeLayer *)generateMaskLayer {
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.bounds;
    
    // 创建一个圆心为父视图中点的圆，半径为父视图宽的2/5，起始角度是从-240°到60°
    
    UIBezierPath *path = nil;
    if ([STLoopProgressView clockWiseType]) {
        path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(SELF_WIDTH / 2, SELF_HEIGHT / 2) radius:SELF_WIDTH / 2.2 startAngle:[STLoopProgressView startAngle] endAngle:[STLoopProgressView endAngle] clockwise:YES];
    } else {
        path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(SELF_WIDTH / 2, SELF_HEIGHT / 2) radius:SELF_WIDTH / 2.2 startAngle:[STLoopProgressView endAngle] endAngle:[STLoopProgressView startAngle] clockwise:NO];
    }
    
    layer.lineWidth = [STLoopProgressView lineWidth];
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor; // 填充色为透明（不设置为黑色）
    layer.strokeColor = [UIColor blackColor].CGColor; // 随便设置一个边框颜色
    layer.lineCap = kCALineCapRound; // 设置线为圆角
    return layer;
}

/**
 *  在修改百分比的时候，修改彩色遮罩的大小
 *
 *  @param persentage 百分比
 */
- (void)setPersentage:(CGFloat)persentage {
    
    _persentage = persentage;
    
    CGPoint handleCenter = [self pointOnCircleAtRadian:DEGREE_TO_RADIAN(360*persentage+90)];
    //去掉隐式动画
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.colorMaskLayer.strokeEnd = persentage;
    _outerCircleLayer.position=handleCenter;
    [CATransaction commit];
}
-(void)drawRect:(CGRect)rect
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.color) {

        self.leftlayer.colors = @[(id)[UIColor colorWithHexString:@"#f88a71"].CGColor,(id)[UIColor colorWithHexString:@"#ffdf5e"].CGColor,(id)[UIColor colorWithHexString:@"#bdd84d"].CGColor,(id)[UIColor colorWithHexString:@"#bdd84d"].CGColor];
        
        self.rightlayer.colors = @[(id)[UIColor colorWithHexString:@"#f88a71"].CGColor,(id)[UIColor colorWithHexString:@"#00a78c"].CGColor,(id)[UIColor colorWithHexString:@"#00a78c"].CGColor,(id)[UIColor colorWithHexString:@"#86b5d1"].CGColor,(id)[UIColor colorWithHexString:@"#bdd84d"].CGColor];
        
        self.leftlayer.locations=@[@0.1,@0.5,@0.7,@0.9];
        
        self.rightlayer.locations=@[@0.2,@0.3,@0.5,@0.7,@0.9];
    }
    else
    {
        self.leftlayer.colors = @[(id)[UIColor whiteColor].CGColor,(id)[UIColor whiteColor].CGColor];
        
        self.rightlayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor];
    }
    [CATransaction commit];
    
    
}

- (void)setupGestureRecognizer {
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(touchDetected:)];
    gestureRecognizer.delegate = self;
    gestureRecognizer.minimumPressDuration = 0.0;
    [self addGestureRecognizer:gestureRecognizer];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {    
    return YES;
}

- (void)touchDetected:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if (UIGestureRecognizerStateEnded == gestureRecognizer.state)
    {
        if (self.didSelectBlock) {
            self.didSelectBlock(self);
        }

    }
}


@end
