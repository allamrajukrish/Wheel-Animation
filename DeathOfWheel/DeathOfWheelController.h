//
//  ViewController.h
//  DeathOfWheel
//
//  Created by Venkat Boddapati on 28/11/12.
//  Copyright (c) 2012 Venkat Boddapati. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface DeathOfWheelController : UIViewController
{
    UIImageView *mShipWheel;
    
    BOOL touchesMoved;
    
    
    CGPoint lastPoint;
    NSTimeInterval lastTouchTimeStamp;
    
    double currentAngle;
    double angularSpeed;
    CATransform3D currentTransform;
    NSInteger turnDirection;
    
    
    CGFloat normalWellnessDialYPosition, normalWellnessDialOverlayYPosition;
    int rotation;
    CGFloat initialAngle;
    CGAffineTransform initialTransform;
    
    
    
}
@property (nonatomic,retain)  IBOutlet UIImageView *mShipWheel;

@property (nonatomic, assign) id rotatingViewDelegate;

//Math Functions//
-(double)DistanceBetweenTwoPoints:(CGPoint)point1:(CGPoint) point2;
-(double)angleBetweenThreePoints:(CGPoint)x :(CGPoint)y :(CGPoint)z;
-(double)crossProduct:(CGPoint)p1 :(CGPoint)p2 :(CGPoint)p3;
-(void)spin:(double)delta;

//Spinning Animation//
- (void)runSpinAnimation;

@end
