
//  ViewController.m
//  DeathOfWheel
//
//  Created by Venkat Boddapati on 28/11/12.
//  Copyright (c) 2012 Venkat Boddapati. All rights reserved.
//

#import "DeathOfWheelController.h"
#define NUMBER_OF_SEGMENTS 9
#define SEGMENT_ROTATION_DIRECTION 0

@interface DeathOfWheelController ()

@end


@implementation DeathOfWheelController
@synthesize mShipWheel;
@synthesize rotatingViewDelegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc
{
    self.mShipWheel = nil;
    [super dealloc];
}

#pragma mark - math functions


CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180 / M_PI;
};

-(double)DistanceBetweenTwoPoints:(CGPoint)point1:(CGPoint) point2
{
	CGFloat dx = point2.x - point1.x;
	CGFloat dy = point2.y - point1.y;
	return sqrt(dx*dx + dy*dy );
}


-(double)angleBetweenThreePoints:(CGPoint)x :(CGPoint)y :(CGPoint)z
{
	double a,b,c;
	
	b = [self DistanceBetweenTwoPoints:x :y];
	a = [self DistanceBetweenTwoPoints:y :z];
	c = [self DistanceBetweenTwoPoints:z :x];
	
	
	double value = (a*a +b*b - c*c)/(2*a*b);
	
	
	return acos(value);
}

-(double)crossProduct:(CGPoint)p1 :(CGPoint)p2 :(CGPoint)p3
{
	CGFloat a1 = p1.x - p2.x;
	CGFloat b1 = p1.y - p2.y;
	
	CGFloat a2 = p3.x - p2.x;
	CGFloat b2 = p3.y - p2.y;
	
	CGFloat slope = a1*b2 - a2*b1;
	
	if (slope < 0)
	{
		return -1;
	}
	else if (slope > 0)
    {
		return 1;
	}
    else
    {
        return 0;
    }
    
}

-(void)spin:(double)delta
{
	currentAngle = currentAngle + delta;
    
	CATransform3D transform = CATransform3DMakeRotation(currentAngle, 0, 0, 1);
	
	[mShipWheel.layer setTransform:transform];
}


#pragma mark - UITouch delegate methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	touchesMoved = FALSE;
	
    //when the wheel is manually stopped
	
    if ([mShipWheel.layer animationForKey:@"transform.rotation.z"])
    {
        CALayer *presentation = (CALayer*)[mShipWheel.layer presentationLayer];
        
        currentTransform = [presentation transform];
        
        double angle = [[presentation valueForKeyPath:@"transform.rotation.z"] doubleValue];
        
        currentAngle = angle;
        
        
        NSLog(@"the angle in degrees is:%f",RadiansToDegrees(angle));
        
        
        [mShipWheel.layer removeAnimationForKey:@"transform.rotation.z"];
        
        [mShipWheel.layer setTransform:currentTransform];
        
    }
    
    UITouch *touch = [[event allTouches] anyObject];
    
    lastPoint = [touch locationInView:self.view];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchesMoved = TRUE;
    
    UITouch *touch = [[event allTouches] anyObject];
    
    // get the touch location
    CGPoint currentPoint = [touch locationInView:self.view];
    
    double theta = [self angleBetweenThreePoints: currentPoint :CGPointMake(512,384):lastPoint];
    
    double sign = [self crossProduct:currentPoint:lastPoint: CGPointMake(512,384)];
    
    
    NSTimeInterval deltaTime = event.timestamp - lastTouchTimeStamp;
    
    angularSpeed = DEGREES_TO_RADIANS(theta)/deltaTime;
    
    turnDirection = sign;
    
    [self spin:sign*theta];
    
    // update the last point
    
    lastPoint = currentPoint;
	
    lastTouchTimeStamp = event.timestamp;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    
    CGPoint currentPoint = [touch locationInView:self.view];
    
    
	if (touchesMoved)
	{
        double deltaAngle = [self angleBetweenThreePoints:currentPoint:CGPointMake(512,384) :lastPoint];
        
        [self spin:deltaAngle];
        
        turnDirection = [self crossProduct:currentPoint:lastPoint: CGPointMake(512,384) ];
        
        NSLog(@" turn direction is %d",turnDirection);
        
        if (angularSpeed > 0.01)
        {
            [self runSpinAnimation];
            
        }
        else {
            [self callDelegateMethods];
        }

        
	}
    
    
}


#pragma mark - Spin Animation

- (void)runSpinAnimation
{
	CAKeyframeAnimation* animation;
	animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
	
    animation.duration = 5; //adjust accordingly
    
	animation.repeatCount = 1;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeBoth;
	
	animation.calculationMode = kCAAnimationLinear;
    
    NSMutableArray *keyFrameValues = [[NSMutableArray alloc] init];
    
    // Start the animation with the current angle of the wheel
    
    double angleAtTheInstant = currentAngle;
    
    double angleTravelled = DEGREES_TO_RADIANS(720)*angularSpeed; // Angle travelled in 1st second
    
    for (int i = 0; i < 10; i ++)
    {
        [keyFrameValues addObject: [NSNumber numberWithDouble:angleAtTheInstant]];
        
        //updating the angle for the next frame
        
        angleAtTheInstant = angleAtTheInstant +angleTravelled*turnDirection;
        
        angleTravelled = angleTravelled*0.8;
        
    }
    
    animation.values = keyFrameValues;
    
    [keyFrameValues release];
    
	animation.keyTimes = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.1],
                          [NSNumber numberWithFloat:0.2],
                          [NSNumber numberWithFloat:0.3],
                          [NSNumber numberWithFloat:0.4],
                          [NSNumber numberWithFloat:0.5],
                          [NSNumber numberWithFloat:0.6],
                          [NSNumber numberWithFloat:0.7],
                          [NSNumber numberWithFloat:0.8],
                          [NSNumber numberWithFloat:1.0], nil];
    
    
	
	animation.delegate = self;
	
    [mShipWheel.layer addAnimation:animation forKey:@"transform.rotation.z"];
	
}

#pragma mark CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    //[self backtonormal];
    
    if (theAnimation == [mShipWheel.layer animationForKey:@"transform.rotation.z"])
    {
        CALayer *presentation = (CALayer*)[mShipWheel.layer presentationLayer];
        
        double angle = [[presentation valueForKeyPath:@"transform.rotation.z"] doubleValue];
        
        currentAngle =  angle;
      
        
        CATransform3D transform = CATransform3DMakeRotation(currentAngle, 0, 0, 1);
        
        [mShipWheel.layer setTransform:transform];
        
        [mShipWheel.layer removeAnimationForKey:@"transform.rotation.z"];
        
            
    }
    
   [self callDelegateMethods];
    // if(flag)
    // {
    // NSLog(@"IVAAVASDASD");
    // [self backtonormal];
    //
    // }
    // [self callDelegateMethods];
    
}

-(void)animationDidStart:(CAAnimation *)anim
{
    NSLog(@"HHH");
}


-(void)backtonormal
{
    CGFloat radians = atan2f(mShipWheel.transform.b, mShipWheel.transform.a);
    CGFloat degrees = radians * (180 / M_PI);
    NSLog(@"Radians is %f",degrees);
    CGFloat segmentAngle = (2 * M_PI / NUMBER_OF_SEGMENTS);
    //[self callDelegateMethods];
    NSLog(@"Current Angle is %f",currentAngle);
}

- (void)callDelegateMethods {
    CGFloat segmentAngle = (2*M_PI / NUMBER_OF_SEGMENTS); // 7 Pieces in the Dial PNG.
    CGFloat currentDialAngle = atan2(self.mShipWheel.transform.b, self.mShipWheel.transform.d);
    // Normalize the angle from 0 to 2Pi.
    currentDialAngle += M_PI;
    NSInteger currentSegment = currentDialAngle / segmentAngle;
    NSInteger newRotation = currentSegment - 3; // Correct for the normalization.
    NSLog(@"b");
    
    NSLog(@"segment rotation is %d",SEGMENT_ROTATION_DIRECTION);
    if (SEGMENT_ROTATION_DIRECTION == 1) {
        if (newRotation <= 0)
            NSLog(@"c");
         //newRotation += NUMBER_OF_SEGMENTS;
        // newRotation = NUMBER_OF_SEGMENTS *10;
        newRotation = NUMBER_OF_SEGMENTS - newRotation;
    }
    else {
        NSLog(@"d");
        if (newRotation < 0)
        {
            NSLog(@"e");
            // newRotation = NUMBER_OF_SEGMENTS *10;
            newRotation += NUMBER_OF_SEGMENTS; // (segment index ranges from 0 to NUMBER_OF_SEGMENTS)
        }
        ////
        NSLog(@"f");
        if ([rotatingViewDelegate respondsToSelector:@selector(viewCirculatedToSegmentIndex:)]) {
            //[rotatingViewDelegate viewCirculatedToSegmentIndex:newRotation];
            NSLog(@"g");
        }
        else {
            NSLog(@"h");
            //[rotatingViewDelegate viewCirculatedToSegmentIndex:newRotation];
        }
        
        
        float angulatedvalue=newRotation*segmentAngle;
          
        CATransform3D transform; 
             
         
        NSLog(@" turn direction is **************** %d",turnDirection);
        
           if(turnDirection>0)
           {
        switch (newRotation) {
                
            case 0:
             
               transform = CATransform3DMakeRotation(-0.2, 0, 0, 1);
                break;
            case 1:
                transform = CATransform3DMakeRotation(0.4, 0, 0, 1);
                break;
            case 2:
                transform = CATransform3DMakeRotation(1.2, 0, 0, 1);
                break;
            case 3:
                transform = CATransform3DMakeRotation(1.8, 0, 0, 1);
                break;
            case 4:
                transform = CATransform3DMakeRotation(2.3, 0, 0, 1);
                break;
            case 5:
                transform = CATransform3DMakeRotation(3.0, 0, 0, 1);
                break;
            case 6:
                transform = CATransform3DMakeRotation(3.7, 0, 0, 1);
                break;
            case 7:
                transform = CATransform3DMakeRotation(4.2, 0, 0, 1);
                break;
                
            case 8:
                transform = CATransform3DMakeRotation(5.0, 0, 0, 1);
                break;
                
            default:
                
                
                break;
        }
           }
        else
        {
            switch (newRotation) {
                    
                case 0:
                    
                    if(angulatedvalue > -0.2)
                    {
                        transform = CATransform3DMakeRotation(5.0, 0, 0, 1);
                        newRotation=8;
                    }
                    else
                    {
                    transform = CATransform3DMakeRotation(-0.2, 0, 0, 1);
                    }
                    break;
                case 1:
                    if((angulatedvalue >-0.2)||(angulatedvalue <0.4))
                    {
                        transform = CATransform3DMakeRotation(-0.2, 0, 0, 1);
                        newRotation=0;
                    }
                    else
                    {
                    transform = CATransform3DMakeRotation(0.4, 0, 0, 1);
                    }
                    
                    break;
                case 2:
                    
                    if((angulatedvalue >0.4)||(angulatedvalue <1.2))
                    {
                    transform = CATransform3DMakeRotation(0.4, 0, 0, 1);
                        newRotation=1;
                    }
                    else
                    {
                     transform = CATransform3DMakeRotation(1.2, 0, 0, 1);   
                    }
                    
                    break;
                case 3:
                    
                    if((angulatedvalue >1.2)||(angulatedvalue <1.8))
                    {
                    transform = CATransform3DMakeRotation(1.2, 0, 0, 1);
                        newRotation=2;
                    }
                    else
                    {

                    transform = CATransform3DMakeRotation(1.8, 0, 0, 1);
                        
                    }
                    break;
                case 4:
                    
                    if((angulatedvalue >1.8)||(angulatedvalue <2.3))
                    {
                    transform = CATransform3DMakeRotation(1.8, 0, 0, 1);
                        newRotation=3;
                    }
                    else
                    {
                        
                    transform = CATransform3DMakeRotation(2.3, 0, 0, 1);
                    }
                    break;
                case 5:
                    if((angulatedvalue >2.3)||(angulatedvalue <3.0))
                    {
                    transform = CATransform3DMakeRotation(2.3, 0, 0, 1);
                        newRotation=4;
                    }
                    else
                    {
                      
                     transform = CATransform3DMakeRotation(3.0, 0, 0, 1);
                    }
                    break;
                case 6:
                    if((angulatedvalue >3.0)||(angulatedvalue <3.7))
                    {
                    transform = CATransform3DMakeRotation(3.0, 0, 0, 1);
                    newRotation=5;
                    }
                    else
                    {
                        
                       transform = CATransform3DMakeRotation(3.7, 0, 0, 1);  
                        
                    }
                    break;
                case 7:
                    if((angulatedvalue >3.7)||(angulatedvalue <4.2))
                    {
                    transform = CATransform3DMakeRotation(3.7, 0, 0, 1);
                        newRotation=6;
                    }
                    else
                    {
                        
                        transform = CATransform3DMakeRotation(4.2,0, 0, 1);
                    }
                    break;
                    
                case 8:
                    if((angulatedvalue >4.2)||(angulatedvalue <5.0))
                    {
                    transform = CATransform3DMakeRotation(4.2, 0, 0, 1);
                        newRotation=7;
                    }
                    else{
                         transform = CATransform3DMakeRotation(5.0, 0, 0, 1);
                    }
                    break;
                    
                default:
                    
                    
                    break;
            }
        }
        
        [UIView animateWithDuration:1.0
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             
                              [mShipWheel.layer setTransform:transform];
                             
                         }
                         completion:NULL];

        
       
        
        NSLog(@"Rotation is %d",newRotation);
        NSLog(@"Rotation is %f",newRotation*segmentAngle);
    }
}


@end
