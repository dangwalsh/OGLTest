//
//  OGLKViewController.m
//  OGLTest
//
//  Created by Daniel Walsh on 8/29/12.
//  Copyright (c) 2012 Daniel Walsh. All rights reserved.
//

#import "OGLKViewController.h"

@interface OGLKViewController () {

    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    float _rotation;
    BOOL _touch;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation OGLKViewController

typedef struct {
    
    float Position[3];
    float Color[4];
    
}Vertex;

const Vertex Vertices[] = {

    {{1, (-1/1.732), (-1/2.449)}, {1, 0, 0, 1}},
    {{0, (2/1.732), (-1/2.449)}, {0, 1, 0, 1}},
    {{0, 0, (3/2.449)}, {0, 0, 1, 1}},
    {{-1, (-1/1.732), (-1/2.449)}, {1, 1, 1, 1}}
/*
    // Front
    {{1, -1, 1}, {1, 0, 0, 1}},
    {{1, 1, 1}, {0, 1, 0, 1}},
    {{-1, 1, 1}, {0, 0, 1, 1}},
    {{-1, -1, 1}, {1, 1, 1, 1}},
    // Back
    {{1, 1, -1}, {1, 0, 0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}},
    {{1, -1, -1}, {0, 0, 1, 1}},
    {{-1, 1, -1}, {1, 1, 1, 1}},
    // Left
    {{-1, -1, 1}, {1, 0, 0, 1}},
    {{-1, 1, 1}, {0, 1, 0, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}},
    {{-1, -1, -1}, {1, 1, 1, 1}},
    // Right
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {0, 1, 0, 1}},
    {{1, 1, 1}, {0, 0, 1, 1}},
    {{1, -1, 1}, {1, 1, 1, 1}},
    // Top
    {{1, 1, 1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {0, 1, 0, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}},
    {{-1, 1, 1}, {1, 1, 1, 1}},
    // Bottom
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, -1, 1}, {0, 1, 0, 1}},
    {{-1, -1, 1}, {0, 0, 1, 1}},
    {{-1, -1, -1}, {1, 1, 1, 1}}
*/
};

const GLubyte Indices[] = {

    0, 1, 2,
    1, 2, 3,
    0, 2, 3,
    3, 0, 1,
    3, 1, 2,
    2, 0, 3
/*
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 5, 6,
    6, 7, 4,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
*/
};

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];    
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad  //create context and view
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //handle error here
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    [self setupGL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - openGL methods

- (void)setupGL //create shader, vertex buffer objects, and attribute pointers
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Color));
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];

    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    self.effect = nil;
}

- (void)update //setup transformation matrices
{
    if(_touch) {
        _rotation += 360 * self.timeSinceLastUpdate;
    }
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), GLKMathDegreesToRadians(_rotation), GLKMathDegreesToRadians(_rotation), 1);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect  //do the drawing
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    [self.effect prepareToDraw];

    //glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    glDrawElements(GL_LINES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touch = !_touch;
}
@end
