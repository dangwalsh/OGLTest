//
//  OGLKViewController.h
//  OGLTest
//
//  Created by Daniel Walsh on 8/29/12.
//  Copyright (c) 2012 Daniel Walsh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface OGLKViewController : GLKViewController {
    GLfloat alpha;
    GLfloat beta;
    GLfloat theta;
    CGPoint pointBegan;
    CGPoint pointMoved;
}

@end
